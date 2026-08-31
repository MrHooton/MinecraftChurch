# doorkeeper.dsc
# Put in: plugins/Denizen/scripts/doorkeeper.dsc
# Then: /denizen reload

doorkeeper_config:
  type: data
  wix_form_url: "https://tinyurl.com/yeypcvjk"  # leave blank if you don't use Wix (or any web form)
  code_expire_minutes: 15

doorkeeper_assign:
  type: assignment
  actions:
    on assignment:
    - trigger name:click state:true

    on click:
    # Connect to database to check for existing code
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s
    
    # Query for existing code by UUID (child_uuid) - each player should have only ONE code
    # Check by UUID first (for Java players), then by name (for Bedrock players without UUID)
    - define sql_query "SELECT * FROM verification_codes WHERE child_uuid='<player.uuid>' OR (child_uuid IS NULL AND child_name='<player.name>') ORDER BY created_at DESC LIMIT 1"
    - ~sql id:db_<queue.id> "query:<[sql_query]>" save:existing_code
    
    # Check if a code was found - if yes, show it and stop (one code per player)
    - define code_rows <entry[existing_code].result_map>
    - if <[code_rows].size> > 0:
      # Code exists - display it (using exact column names from schema: code, child_name, child_uuid, created_at, expires_at, used_at)
      - define code_map <[code_rows].get[1]>
      - define code <[code_map].get[code]>
      - define child_name <[code_map].get[child_name]>
      - define child_uuid <[code_map].get[child_uuid]>
      - define expires_at <[code_map].get[expires_at]>
      - define created_at <[code_map].get[created_at]>
      - define used_at <[code_map].get[used_at]>
      
      # Display the existing code
      - narrate "<&7>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━<&r>"
      - narrate "<&7>You already have a verification code!<&r>"
      - narrate ""
      - narrate "<&a>Your verification code is:<&r>"
      - narrate "<&b><&l>    <[code]>    <&r>"
      - narrate ""
      - if <[used_at].is_empty>:
        - narrate "<&7>Status: <&a>Active (Not Used)<&r>"
      - else:
        - narrate "<&7>Status: <&c>Already Used<&r>"
      - narrate "<&7>Created: <[created_at]><&r>"
      - narrate "<&7>Expires: <[expires_at]><&r>"
      - narrate ""
      - narrate "<&7>Check your inventory for the book with full details.<&r>"
      - narrate "<&7>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━<&r>"
      - sql disconnect id:db_<queue.id>
      - stop
    
    # No code found - generate a new one
    - sql disconnect id:db_<queue.id>
    
    - define wix_form_url <script[doorkeeper_config].data_key[wix_form_url]>
    - define expire_mins <script[doorkeeper_config].data_key[code_expire_minutes]>

    - narrate "<&7>Welcome! I'll help you get a verification code.<&r>"
    - narrate "<&7>Please wait a moment...<&r>"

    - run verification_init

    - define now <util.time_now>
    - define expires_at <[now].add[<[expire_mins]>m]>

    # Use positional defs for compatibility: child_name|child_uuid|expires_at
    # Use ~run so this queue WAITS for the SQL task to finish.
    - ~run verification_create_code def:<player.name>|<player.uuid>|<[expires_at]> save:code_result
    # Old Denizen: saved run entries don't always expose determination reliably.
    # Use a player flag set by `verification_create_code` instead.
    - define code <player.flag[verification_code].if_null[]>
    - flag <player> verification_code:!

    # Older Denizen builds: no is_empty -> use length check
    - if <[code].length> < 1:
      - narrate "<&c>Sorry, I couldn't generate a code right now.<&r>"
      - narrate "<&7>Please try again later or contact a grown-up for help.<&r>"
      - ~log "Doorkeeper error: Failed to generate code for player=<player.name>/<player.uuid>" type:warning file:logs/doorkeeper.log
      - stop

    - define book_title "Verification Code"
    - define page1_text "Hello <player.name>!\n\nYour verification code is:\n\n<&a><[code]><&r>\n\nIt expires in <[expire_mins]> minutes.\n\nPlease give this code to a parent or guardian."

    # Only include web-form instructions if URL is set
    - define page2_text "Ask a parent/guardian for help using this code."
    - if <[wix_form_url].length> > 5:
      - define page2_text "Instructions:\n\n1) Open: <[wix_form_url]>\n2) Fill in your name and this code\n3) Wait for approval\n\nYou'll be able to access more areas once approved!"

    # Older Denizen doesn't support direct written_book mechanisms (title/author/pages).
    # Use legacy "book" map format instead.
    - define book i@written_book[book=map@[title=<[book_title]>;author=Doorkeeper;pages=li@<[page1_text]>|<[page2_text]>]]
    - give <[book]> to:<player.inventory>

    - flag <player> doorkeeper_code_generated:true

    - narrate "<&a>✓ Verification code generated!<&r>"
    - narrate "<&7>Check your inventory for a book with your code.<&r>"
    - announce "<&7>[DOORKEEPER] Generated code=<[code]> for child_name=<player.name> child_uuid=<player.uuid>" to_console

player_join_registration:
  type: world
  debug: false
  events:
    on player joins:
    - announce "<&7>[DOORKEEPER] Player <player.name> joined server" to_console
    - run verification_init
    - run doorkeeper_register_player

doorkeeper_register_player:
  type: task
  script:
    # Register player in MySQL database
    - announce "<&7>[DOORKEEPER] Registering player <player.name>..." to_console
    - define platform "java"
    - if <player.has_flag[floodgate.is_bedrock_player]>:
      - define platform "bedrock"

    # Use MySQL-based registration (handles both insert and update automatically)
    - run verification_register_player def:<player.name>|<player.uuid>|<[platform]>
