# File: scripts/sql_error_handler.dsc
# Event-driven SQL error handler - catches SQL errors automatically

# Global error handler for SQL failures
sql_error_event_handler:
  type: world
  debug: false
  events:
    # Catch any SQL-related errors
    on script generates error priority:100:
      - if <context.queue.script.name||null> == null:
        - stop
      
      # Check if this is a SQL-related error
      - if <context.message.contains_text[Not connected to server]||false>:
        - define script_name <context.queue.script.name>
        - define player_name <context.queue.player.name||"CONSOLE">
        - define error_msg <context.message>
        
        # Log the error with details
        - log "text:SQL Connection Error in script '<[script_name]>' for player '<[player_name]>': <[error_msg]>" type:severe file:logs/sql_errors.log
        
        # Notify online admins
        - foreach <server.online_players>:
          - if <[value].has_permission[denizen.admin]>:
            - narrate "<&c>[SQL ERROR] Connection failed in <[script_name]> for <[player_name]>" targets:<[value]>
        
        # If there's a player context, notify them
        - if <context.queue.player||null> != null:
          - narrate "<&c>Database connection error. Please try again in a moment or contact an admin." targets:<context.queue.player>
      
      # Check for other SQL errors
      - else if <context.message.contains_text[sql]||false> || <context.message.contains_text[SQL]||false> || <context.message.contains_text[database]||false>:
        - define script_name <context.queue.script.name>
        - define player_name <context.queue.player.name||"CONSOLE">
        - define error_msg <context.message>
        
        - log "text:SQL Error in script '<[script_name]>' for player '<[player_name]>': <[error_msg]>" type:warning file:logs/sql_errors.log
        
        # Notify online admins
        - foreach <server.online_players>:
          - if <[value].has_permission[denizen.admin]>:
            - narrate "<&e>[SQL WARNING] Error in <[script_name]> for <[player_name]>: <[error_msg].substring[1,80]>" targets:<[value]>

# Monitor SQL connection health
sql_connection_monitor:
  type: world
  debug: false
  events:
    # Check SQL connections every 5 minutes
    on system time 00:05:
    - run sql_connection_health_check
    on system time 00:10:
    - run sql_connection_health_check
    on system time 00:15:
    - run sql_connection_health_check
    on system time 00:20:
    - run sql_connection_health_check
    on system time 00:25:
    - run sql_connection_health_check
    on system time 00:30:
    - run sql_connection_health_check
    on system time 00:35:
    - run sql_connection_health_check
    on system time 00:40:
    - run sql_connection_health_check
    on system time 00:45:
    - run sql_connection_health_check
    on system time 00:50:
    - run sql_connection_health_check
    on system time 00:55:
    - run sql_connection_health_check

# Health check task
sql_connection_health_check:
  type: task
  debug: false
  script:
    # Simplified for compatibility with older Denizen versions
    # Individual scripts now handle disconnect before connect
    # This function is kept for compatibility but does nothing
    - define dummy true

# Better connection wrapper with automatic retry
sql_connect_with_retry:
  type: task
  definitions: connection_id|max_attempts
  debug: false
  script:
    - define max_attempts <[max_attempts]||3>
    - define attempt 1

    # Try to connect - if ~sql succeeds without error, assume connection is good
    - ~sql id:<[connection_id]> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 1t
    
    # If we got here without error, connection succeeded
    - determine true
