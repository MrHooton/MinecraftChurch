doorkeeper_assign:
  type: assignment
  actions:
    on assignment:
    - trigger name:click state:true

    on click:
    # Check if player already has a pending code (optional - prevent spam)
    - define already_has_code <player.has_flag[doorkeeper_code_generated].is[true]>
    - if <[already_has_code]> {
      - narrate "<&7>You already have a verification code. Check your inventory for the book.<&r>"
      - stop
    }
    
    # Load API configuration
    - define config <entry[api_config].as[data]>
    - define api_url "<[config].read[api_url]>"
    - define api_secret "<[config].read[api_secret]>"
    - define wix_form_url "<[config].read[wix_form_url]>"
    
    # Validate configuration (only URL is required, secret is optional)
    - if <[api_url].equals[YOUR_API_URL]> {
      - narrate "<&c>Configuration error. Please contact an administrator.<&r>"
      - log "ERROR: Doorkeeper API URL not set! Edit api_config.dsc"
      - stop
    }
    
    # Generate verification code via API
    - narrate "<&7>Welcome! I'll help you get a verification code.<&r>"
    - narrate "<&7>Please wait a moment...<&r>"
    
    # Prepare request data
    - define request_json "{\"child_name\":\"<player.name>\",\"child_uuid\":\"<player.uuid>\"}"
    - define full_url "<[api_url]>"
    - if !<[full_url].contains[/api/codes/generate]> {
      - define full_url "<[api_url]>/api/codes/generate"
    }
    
    # Call API to generate code using webget
    # Build headers (only include secret if configured)
    - define headers <list[Content-Type|application/json]>
    - if !<[api_secret].equals[YOUR_API_SECRET].and[<[api_secret].is[>].to[0]>]> {
      - define headers <[headers].include[X-API-Secret|<[api_secret]>]>
    }
    - webget url:"<[full_url]>"
      method:POST
      headers:<[headers]>
      post:<[request_json]>
      save:code_response
    
    # Check if API call succeeded
    - define response_code <[code_response].http_status_code>
    - if <[response_code].is[201].or[<[response_code].is[200]>]> {
      # Success - parse response
      - define response_json <[code_response].http_response_body.parse_json>
      - define verification_code <[response_json].get[code]>
      - define expires_at <[response_json].get[expires_at]>
      
      # Create written book with code, URL, and player name
      - define book_title "Verification Code"
      - define page1_text "Hello <player.name>!\n\nYour verification code is:\n\n<&b><&bold><[verification_code]><&r>\n\nThis code expires in 15 minutes.\n\nPlease give this code to a parent or guardian."
      - define page2_text "Instructions:\n\n1. Go to this website:\n<&u><[wix_form_url]><&r>\n\n2. Fill out the form with:\n- Your name: <player.name>\n- This code: <[verification_code]>\n\n3. Wait for approval.\n\nYou'll be able to access more areas once approved!"
      
      # Create the written book item
      # Note: Denizen book creation syntax
      - define book <item[written_book].with[title].as[<[book_title]>].with[author].as[Doorkeeper].with[page[1]].as[<[page1_text]>].with[page[2]].as[<[page2_text]>]>
      
      # Give book to player
      - inventory add <[book]> <player>
      
      # Mark that code was generated (prevents spam)
      - flag <player> doorkeeper_code_generated:true
      
      # Success message
      - narrate "<&a>✓ Verification code generated!<&r>"
      - narrate "<&7>Check your inventory for a book with your code and instructions.<&r>"
      - narrate "<&7>Give the code to a parent or guardian to complete verification.<&r>"
      
    } else {
      # API call failed
      - define error_body <[code_response].http_response_body>
      - narrate "<&c>Sorry, I couldn't generate a code right now.<&r>"
      - narrate "<&7>Please contact a grown-up for help.<&r>"
      - log "Doorkeeper API error for <player.name>: HTTP <[response_code]> - <[error_body]>"
    }
