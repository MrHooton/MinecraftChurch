# File: scripts/verification_storage_mysql.dsc
# FULL UPDATED (compatible with older Denizen builds - no <run[]> tags, no .is_empty)
# Includes:
# - verification_init (unchanged)
# - verification_register_player (your original)
# - verification_create_code (fixed: no .is_empty)
# - verification_read_player (fixed disconnect)
# - verification_get_codes (fixed disconnect)
# - auto-register on join event
# - /mycode (NEW: checks verification_requests first, then verification_codes, else generates)
# - /verifyrequest (NEW: prevents duplicate pending request; creates request using existing/new code)
# - verification_create_request (NEW: inserts into verification_requests and reuses code)

# ------------------------------------------------------------
# Init (unchanged)
# ------------------------------------------------------------
verification_init:
  type: task
  script:
    - narrate "MySQL database initialized (tables should already exist)"

# ------------------------------------------------------------
# Auto-register on join (recommended)
# ------------------------------------------------------------
verification_player_join_event:
  # Disabled: registration is handled by `doorkeeper_fixed.dsc` (detects Java vs Bedrock)
  # Older Denizen builds will error if a `type: world` script has an empty `events:` block,
  # so keep this as a non-world script.
  type: data
  debug: false
  disabled: true

# ------------------------------------------------------------
# Register or update player in known_players table (your original)
# ------------------------------------------------------------
verification_register_player:
  type: task
  definitions: player_name|uuid|platform
  script:
    - announce "<&7>[REGISTER] Attempting to register player: <[player_name]> (<[uuid]>)" to_console
    
    - announce "<&7>[REGISTER] Connecting to database..." to_console
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 1t
    
    - announce "<&7>[REGISTER] Database connected, executing registration query..." to_console
    
    - define sql_query "INSERT INTO known_players (player_name, uuid, platform, first_seen_at, last_seen_at) VALUES ('<[player_name]>', '<[uuid]>', '<[platform]>', NOW(), NOW()) ON DUPLICATE KEY UPDATE uuid='<[uuid]>', platform='<[platform]>', last_seen_at=NOW()"
    - announce "<&7>[REGISTER] Query: <[sql_query]>" to_console
    
    - ~sql id:db_<queue.id> "update:<[sql_query]>"
    
    - announce "<&a>[REGISTER] Player <[player_name]> successfully registered/updated in database!" to_console
    - sql disconnect id:db_<queue.id>

# ------------------------------------------------------------
# Create (or reuse) verification code in verification_codes (your original, fixed)
# One code per player (by UUID). Returns code via determine.
# ------------------------------------------------------------
verification_create_code:
  type: task
  definitions: child_name|child_uuid|expires_at
  script:
    # Connect to database (avoid save/determine propagation issues on older Denizen builds)
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 1t
    
    # Check if a code already exists for this player (by UUID or by name if UUID is NULL)
    - if <[child_uuid].length> < 1:
      - define check_query "SELECT code, expires_at FROM verification_codes WHERE child_name='<[child_name]>' AND child_uuid IS NULL LIMIT 1"
    - else:
      - define check_query "SELECT code, expires_at FROM verification_codes WHERE child_uuid='<[child_uuid]>' LIMIT 1"
    - ~sql id:db_<queue.id> "query:<[check_query]>" save:existing_check

    # If code already exists, return it instead of generating a new one
    - define existing_rows <entry[existing_check].result_map>
    - if <[existing_rows].size> > 0:
      - define existing_code_map <[existing_rows].get[1]>
      - define code <[existing_code_map].get[code]>
      - define existing_expires <[existing_code_map].get[expires_at].if_null[]>
      # Backfill expires_at if missing (some DB installs may not have the trigger/default)
      - if <[existing_expires].length> < 1:
        - define fix_exp_query "UPDATE verification_codes SET expires_at=DATE_ADD(NOW(), INTERVAL 15 MINUTE) WHERE code='<[code]>' LIMIT 1"
        - ~sql id:db_<queue.id> "update:<[fix_exp_query]>"
      - narrate "Code already exists for this player: <[code]>"
      - if <player.is_player||false>:
        - flag <player> verification_code:<[code]>
      - sql disconnect id:db_<queue.id>
      - determine <[code]>

    # No existing code found - generate a new one
    - define chars "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    - define code ""
    - repeat 6:
        - define random_index <util.random.int[1].to[<[chars].length>]>
        - define char <[chars].substring[<[random_index]>,<[random_index]>]>
        - define code "<[code]><[char]>"

    # Collision check
    - define collision_check "SELECT code FROM verification_codes WHERE code='<[code]>' LIMIT 1"
    - ~sql id:db_<queue.id> "query:<[collision_check]>" save:collision_result
    - define collision_rows <entry[collision_result].result_map>

    - if <[collision_rows].size> > 0:
      - log "text:Code collision detected for <[code]>, generating new code" type:info file:logs/verification_errors.log
      - define code ""
      - repeat 6:
          - define random_index <util.random.int[1].to[<[chars].length>]>
          - define char <[chars].substring[<[random_index]>,<[random_index]>]>
          - define code "<[code]><[char]>"
      - define collision_check "SELECT code FROM verification_codes WHERE code='<[code]>' LIMIT 1"
      - ~sql id:db_<queue.id> "query:<[collision_check]>" save:collision_result2
      - define collision_rows2 <entry[collision_result2].result_map>
      - if <[collision_rows2].size> > 0:
        - log "text:Warning: Code collision again for <[child_name]>, using code <[code]> anyway" type:warning file:logs/verification_errors.log

    # Insert the code into the database
    - if <[child_uuid].length> < 1:
      - define sql_query "INSERT INTO verification_codes (code, child_name, child_uuid, expires_at) VALUES ('<[code]>', '<[child_name]>', NULL, DATE_ADD(NOW(), INTERVAL 15 MINUTE))"
    - else:
      - define sql_query "INSERT INTO verification_codes (code, child_name, child_uuid, expires_at) VALUES ('<[code]>', '<[child_name]>', '<[child_uuid]>', DATE_ADD(NOW(), INTERVAL 15 MINUTE))"

    - narrate "SQL Query: <[sql_query]>"
    - narrate "Attempting to insert code <[code]> for <[child_name]>..."
    - ~sql id:db_<queue.id> "update:<[sql_query]>"

    # Verify insert
    - wait 1s
    - define verify_query "SELECT code FROM verification_codes WHERE code='<[code]>' AND child_name='<[child_name]>'"
    - ~sql id:db_<queue.id> "query:<[verify_query]>" save:verify_code

    - define verify_rows <entry[verify_code].result_map>
    - if <[verify_rows].size> > 0:
      - narrate "✓ Verification code <[code]> successfully inserted into database for <[child_name]>"
      - if <player.is_player||false>:
        - flag <player> verification_code:<[code]>
      - sql disconnect id:db_<queue.id>
      - determine <[code]>
    - else:
      - narrate "✗ ERROR: Failed to insert verification code <[code]> into database!"
      - log "text:Failed to insert verification code: code=<[code]>, child_name=<[child_name]>, child_uuid=<[child_uuid]>" type:severe file:logs/verification_errors.log
      - sql disconnect id:db_<queue.id>
      - define code ""
      - determine <[code]>

# ------------------------------------------------------------
# Read player data (fixed disconnect)
# ------------------------------------------------------------
verification_read_player:
  type: task
  definitions: player_name
  script:
    # Try to connect to database with automatic retry
    - ~run sql_connect_with_retry def:db_<queue.id>|3 save:conn_success
    - if <entry[conn_success].determination||false> == false:
      - determine null
    
    - define sql_query "SELECT * FROM known_players WHERE player_name='<[player_name]>'"
    - narrate "SQL Query: <[sql_query]>"

    - ~sql id:db_<queue.id> "query:<[sql_query]>" save:read_player
    - define rows <entry[read_player].result_map>
    - sql disconnect id:db_<queue.id>

    - if <[rows].size> > 0:
      - define row <[rows].get[1]>
      - determine <[row]>
    - else:
      - determine null

# ------------------------------------------------------------
# Get all codes for a child (fixed disconnect)
# ------------------------------------------------------------
verification_get_codes:
  type: task
  definitions: child_name
  script:
    # Try to connect to database with automatic retry
    - ~run sql_connect_with_retry def:db_<queue.id>|3 save:conn_success
    - if <entry[conn_success].determination||false> == false:
      - determine <list>
    
    - define sql_query "SELECT * FROM verification_codes WHERE child_name='<[child_name]>' ORDER BY created_at DESC"
    - narrate "SQL Query: <[sql_query]>"

    - ~sql id:db_<queue.id> "query:<[sql_query]>" save:get_codes
    - define rows <entry[get_codes].result_map>
    - sql disconnect id:db_<queue.id>
    - determine <[rows]>

# ------------------------------------------------------------
# COMMAND: /mycode
# Priority:
# 1) If existing PENDING request -> show request.code (do NOT generate new)
# 2) Else if existing verification_codes row -> show it
# 3) Else generate + insert new verification_codes row
# ------------------------------------------------------------
verification_mycode_command:
  type: command
  name: mycode
  description: Show your verification code (reuses existing pending request code if present)
  usage: /mycode
  permission: minecraftchurch.verify
  script:
    - if <context.source_type> != player:
      - narrate "<&c>This command can only be used in-game."
      - determine cancelled

    - define child_name <player.name>
    - define child_uuid <player.uuid>
    - narrate "<&7>Checking your verification code..."

    # Try to connect to database with automatic retry
    - ~run sql_connect_with_retry def:db_<queue.id>|3 save:conn_success
    - if <entry[conn_success].determination||false> == false:
      - narrate "<&c>Database temporarily unavailable. Please try again in a moment."
      - determine cancelled
    
    # 1) pending request?
    - define req_query "SELECT code FROM verification_requests WHERE child_name='<[child_name]>' AND status='pending' ORDER BY created_at DESC LIMIT 1"
    - ~sql id:db_<queue.id> "query:<[req_query]>" save:req_check
    - define req_rows <entry[req_check].result_map>
    - if <[req_rows].size> > 0:
      - define code <[req_rows].get[1].get[code].if_null[]>
      - sql disconnect id:db_<queue.id>
      - if <[code].length> < 1:
        - narrate "<&c>Your pending request exists, but the code is missing. Please contact staff."
        - determine cancelled
      - narrate "<&a>Your verification code is: <&b><[code]><&r>"
      - narrate "<&7>(Reused from your existing pending request.)"
      - determine cancelled

    # 2) existing code?
    - define code_query "SELECT code FROM verification_codes WHERE child_uuid='<[child_uuid]>' LIMIT 1"
    - ~sql id:db_<queue.id> "query:<[code_query]>" save:code_check
    - define code_rows <entry[code_check].result_map>
    - if <[code_rows].size> > 0:
      - define code <[code_rows].get[1].get[code].if_null[]>
      - sql disconnect id:db_<queue.id>
      - if <[code].length> < 1:
        - narrate "<&c>Found a code row, but code is empty. Please contact staff."
        - determine cancelled
      - narrate "<&a>Your verification code is: <&b><[code]><&r>"
      - narrate "<&7>Give this code to your parent/guardian."
      - determine cancelled

    # 3) generate new
    - define chars "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    - define code ""
    - repeat 6:
        - define random_index <util.random.int[1].to[<[chars].length>]>
        - define char <[chars].substring[<[random_index]>,<[random_index]>]>
        - define code "<[code]><[char]>"

    - define collision_check "SELECT code FROM verification_codes WHERE code='<[code]>' LIMIT 1"
    - ~sql id:db_<queue.id> "query:<[collision_check]>" save:collision_result
    - define collision_rows <entry[collision_result].result_map>
    - if <[collision_rows].size> > 0:
      - define code ""
      - repeat 6:
          - define random_index <util.random.int[1].to[<[chars].length>]>
          - define char <[chars].substring[<[random_index]>,<[random_index]>]>
          - define code "<[code]><[char]>"

    - define insert_query "INSERT INTO verification_codes (code, child_name, child_uuid) VALUES ('<[code]>', '<[child_name]>', '<[child_uuid]>')"
    - ~sql id:db_<queue.id> "update:<[insert_query]>"
    - sql disconnect id:db_<queue.id>

    - narrate "<&a>Your verification code is: <&b><[code]><&r>"
    - narrate "<&7>Give this code to your parent/guardian."

# ------------------------------------------------------------
# COMMAND: /verifyrequest <parent_email> [parent_name] [adult_name]
# Behavior:
# - If pending request exists: show the existing request code and do NOT create new request
# - Else: get code (existing or create new) then create verification_requests row
# ------------------------------------------------------------
verification_verifyrequest_command:
  type: command
  name: verifyrequest
  description: Submit a verification request
  usage: /verifyrequest [parent_email] (parent_name) (adult_name)
  permission: minecraftchurch.verify
  script:
    - if <context.source_type> != player:
      - narrate "<&c>This command can only be used in-game."
      - determine cancelled

    - if <context.args.size> < 1:
      - narrate "<&c>Usage: /verifyrequest [parent_email] (parent_name) (adult_name)"
      - narrate "<&7>Example: /verifyrequest parent@email.com"
      - narrate "<&7>Example: /verifyrequest parent@email.com John_Doe"
      - narrate "<&7>Example: /verifyrequest parent@email.com John_Doe AdultPlayer"
      - determine cancelled

    - define child_name <player.name>
    - define child_uuid <player.uuid>
    - define parent_email <context.args.get[1]>
    - define parent_name ""
    - define adult_name ""
    - if <context.args.size> >= 2:
      - define parent_name <context.args.get[2]>
    - if <context.args.size> >= 3:
      - define adult_name <context.args.get[3]>

    - narrate "<&7>Submitting verification request..."

    # Create request task will:
    # - reuse existing pending request code (and not create a new request)
    # - else reuse or create a code, then insert new request
    - run verification_create_request_storage def:<[child_name]>|<[child_uuid]>|<[parent_email]>|<[parent_name]>|<[adult_name]>

# ------------------------------------------------------------
# TASK: Create request (or reuse existing)
# Definitions: child_name|child_uuid|parent_email|parent_name|adult_name
# ------------------------------------------------------------
verification_create_request_storage:
  type: task
  definitions: child_name|child_uuid|parent_email|parent_name|adult_name
  script:
    # Try to connect to database with automatic retry
    - ~run sql_connect_with_retry def:db_<queue.id>|3 save:conn_success
    - if <entry[conn_success].determination||false> == false:
      - narrate "<&c>Database temporarily unavailable. Please try again in a moment."
      - determine false
    
    # 1) If pending request exists, reuse it
    - define req_query "SELECT id, code FROM verification_requests WHERE child_name='<[child_name]>' AND status='pending' ORDER BY created_at DESC LIMIT 1"
    - ~sql id:db_<queue.id> "query:<[req_query]>" save:req_check
    - define req_rows <entry[req_check].result_map>
    - if <[req_rows].size> > 0:
      - define req_id <[req_rows].get[1].get[id].if_null[?]>
      - define code <[req_rows].get[1].get[code].if_null[]>
      - sql disconnect id:db_<queue.id>
      - narrate "<&e>You already have a pending request (ID: <&b><[req_id]><&e>)."
      - if <[code].length> > 0:
        - narrate "<&7>Your code: <&b><[code]>"
      - narrate "<&7>Please wait for an admin to approve/reject it."
      - determine false

    # 2) Get existing code from verification_codes, else generate/insert
    - define code_query "SELECT code FROM verification_codes WHERE child_uuid='<[child_uuid]>' LIMIT 1"
    - ~sql id:db_<queue.id> "query:<[code_query]>" save:code_check
    - define code_rows <entry[code_check].result_map>
    - define code ""
    - if <[code_rows].size> > 0:
      - define code <[code_rows].get[1].get[code].if_null[]>

    - if <[code].length> < 1:
      - define chars "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
      - define code ""
      - repeat 6:
          - define random_index <util.random.int[1].to[<[chars].length>]>
          - define char <[chars].substring[<[random_index]>,<[random_index]>]>
          - define code "<[code]><[char]>"
      - define collision_check "SELECT code FROM verification_codes WHERE code='<[code]>' LIMIT 1"
      - ~sql id:db_<queue.id> "query:<[collision_check]>" save:collision_result
      - define collision_rows <entry[collision_result].result_map>
      - if <[collision_rows].size> > 0:
        - define code ""
        - repeat 6:
            - define random_index <util.random.int[1].to[<[chars].length>]>
            - define char <[chars].substring[<[random_index]>,<[random_index]>]>
            - define code "<[code]><[char]>"
      - define insert_code_query "INSERT INTO verification_codes (code, child_name, child_uuid) VALUES ('<[code]>', '<[child_name]>', '<[child_uuid]>')"
      - ~sql id:db_<queue.id> "update:<[insert_code_query]>"

    # 3) Insert new request
    - define email_esc <[parent_email].if_null[].replace[']][\\']]>
    - define parent_esc <[parent_name].if_null[].replace[']][\\']]>
    - define adult_esc <[adult_name].if_null[].replace[']][\\']]>

    - define insert_req_query "INSERT INTO verification_requests (child_name, parent_name, parent_email, adult_name, code, status, created_at) VALUES ('<[child_name]>', '<[parent_esc]>', '<[email_esc]>', '<[adult_esc]>', '<[code]>', 'pending', NOW())"
    - ~sql id:db_<queue.id> "update:<[insert_req_query]>"

    # Get new request id
    - define id_query "SELECT LAST_INSERT_ID() AS new_id"
    - ~sql id:db_<queue.id> "query:<[id_query]>" save:newid_check
    - define id_rows <entry[newid_check].result_map>
    - define new_id "?"
    - if <[id_rows].size> > 0:
      - define new_id <[id_rows].get[1].get[new_id].if_null[?]>

    - sql disconnect id:db_<queue.id>

    - narrate "<&a>✓ Verification request submitted!"
    - narrate "<&7>Request ID: <&b><[new_id]>"
    - narrate "<&7>Your code: <&b><[code]>"
    - narrate "<&7>An admin will review it soon."
    - determine true
