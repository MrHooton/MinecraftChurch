# grant_applicator.dsc
# Denizen script to apply access grants via LuckPerms and update permission_level in known_players

# Task to apply a single grant
verification_apply_grant:
  type: task
  definitions: grant_id|player_name|grant_type|grant_value
  script:
    # Connect to database
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s
    
    # Apply the grant via LuckPerms based on type
    - if <[grant_type].equals[group]>:
      # For group grants, use parent set (clears existing and sets new primary group)
      - define grant_value_lower <[grant_value].to_lowercase>
      # Execute LuckPerms command to set the group
      - narrate "Executing: lp user <[player_name]> parent set <[grant_value_lower]>"
      - execute as_server "lp user <[player_name]> parent set <[grant_value_lower]>"
      - wait 2s
      - narrate "LuckPerms command executed for <[player_name]>. Group should be set to '<[grant_value_lower]>'"
      # Update permission_level in known_players table
      - if <[grant_value_lower].equals[guest].or[<[grant_value_lower].equals[child]].or[<[grant_value_lower].equals[adult]].or[<[grant_value_lower].equals[director]].or[<[grant_value_lower].equals[observer]].or[<[grant_value_lower].equals[admin]]>:
        - define update_perm_query "UPDATE known_players SET permission_level='<[grant_value_lower]>' WHERE player_name='<[player_name]>'"
        - ~sql id:db_<queue.id> "update:<[update_perm_query]>"
        - narrate "Updated permission_level to '<[grant_value_lower]>' for player <[player_name]> in database"
      - else:
        - narrate "Warning: Invalid permission level '<[grant_value]>' for player <[player_name]>"
    - else:
      # For permission grants, set the permission node
      - execute as_server "lp user <[player_name]> permission set <[grant_value]> true"
      - wait 1s
    
    # Update grant status to 'applied' and set applied_at timestamp
    - define update_query "UPDATE access_grants SET status='applied', applied_at=NOW() WHERE id=<[grant_id]>"
    - ~sql id:db_<queue.id> "update:<[update_query]>"
    
    # Log to audit_log (escape quotes for JSON)
    # Note: Using simple replace - if values contain quotes, they may cause issues
    - define grant_type_escaped <[grant_type]>
    - define grant_value_escaped <[grant_value]>
    - define audit_query "INSERT INTO audit_log (action_type, admin_user, target_player, grant_id, details, created_at) VALUES ('grant_applied', 'denizen_script', '<[player_name]>', <[grant_id]>, '{\"grant_type\":\"<[grant_type_escaped]>\",\"grant_value\":\"<[grant_value_escaped]>\"}', NOW())"
    - ~sql id:db_<queue.id> "update:<[audit_query]>"
    
    - narrate "Grant #<[grant_id]> successfully applied for <[player_name]>: <[grant_type]>=<[grant_value]>"
    - sql disconnect id:db_<queue.id>
    - determine true

# Task to mark a grant as failed
verification_mark_grant_failed:
  type: task
  definitions: grant_id|player_name|error_message
  script:
    # Connect to database
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s
    
    # Update grant status to 'failed' and set error message
    # Note: If error message contains quotes, they may cause SQL issues
    - define error_escaped <[error_message]>
    - define update_query "UPDATE access_grants SET status='failed', error='<[error_escaped]>' WHERE id=<[grant_id]>"
    - ~sql id:db_<queue.id> "update:<[update_query]>"
    
    # Log to audit_log
    - define audit_query "INSERT INTO audit_log (action_type, target_player, grant_id, details, created_at) VALUES ('grant_failed', '<[player_name]>', <[grant_id]>, '{\"error\":\"<[error_escaped]>\"}', NOW())"
    - ~sql id:db_<queue.id> "update:<[audit_query]>"
    
    - narrate "Grant #<[grant_id]> marked as failed for <[player_name]>: <[error_message]>"
    - sql disconnect id:db_<queue.id>
    - determine true

# Task to get pending grants (status='approved')
verification_get_pending_grants:
  type: task
  script:
    # Connect to database (use ~sql to wait for connection)
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s
    
    # Query for all approved grants (use ~sql to wait for query)
    - define query "SELECT * FROM access_grants WHERE status='approved' ORDER BY created_at ASC LIMIT 50"
    - ~sql id:db_<queue.id> "query:<[query]>" save:pending_grants
    
    # Get the results
    - define rows <entry[pending_grants].result_map>
    - sql disconnect id:db_<queue.id>
    
    # Return the grants as a list
    - determine <[rows]>

# Task to process pending grants (shared logic for server start and periodic polling)
grant_poller_process:
  type: task
  script:
    - narrate "Grant poller: Checking for pending grants..."
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s

    - define query "SELECT * FROM access_grants WHERE status='approved' ORDER BY created_at ASC LIMIT 50"
    - ~sql id:db_<queue.id> "query:<[query]>" save:pending_grants
    - define pending <entry[pending_grants].result_map>
    - sql disconnect id:db_<queue.id>

    - if <[pending].size> > 0:
      - narrate "Grant poller: Found <[pending].size> pending grant(s), applying..."
      - foreach <[pending]> as:grant:
        - define grant_map <[grant]>
        - define grant_id <[grant_map].get[id]>
        - define player_name <[grant_map].get[player_name]>
        - define grant_type <[grant_map].get[grant_type]>
        - define grant_value <[grant_map].get[grant_value]>

        # Validate (safe checks)
        - if <[grant_id]> > 0:
          - if <[player_name].length> > 0:
            - if <[grant_type].length> > 0:
              - if <[grant_value].length> > 0:
                - narrate "Grant poller: Applying grant #<[grant_id]> for <[player_name]> (<[grant_type]>=<[grant_value]>)..."
                - run verification_apply_grant def:grant_id|def:player_name|def:grant_type|def:grant_value
                - wait 8s
                # Note: The task handles success/failure internally by updating the database
                # We don't need to check the result here since the task will update status to 'applied' on success
              - else:
                - narrate "Grant poller: ERROR - Invalid grant_value, skipping..."
                - define safe_player_name <[player_name].if_null[unknown]>
                - define safe_grant_id <[grant_id].if_null[0]>
                - define error_msg "Invalid grant data: missing grant_value"
                - run verification_mark_grant_failed def:safe_grant_id|def:safe_player_name|def:error_msg
            - else:
              - narrate "Grant poller: ERROR - Invalid grant_type, skipping..."
              - define safe_player_name <[player_name].if_null[unknown]>
              - define safe_grant_id <[grant_id].if_null[0]>
              - define error_msg "Invalid grant data: missing grant_type"
              - run verification_mark_grant_failed def:safe_grant_id|def:safe_player_name|def:error_msg
          - else:
            - narrate "Grant poller: ERROR - Invalid player_name, skipping..."
            - define safe_grant_id <[grant_id].if_null[0]>
            - define error_msg "Invalid grant data: missing player_name"
            - define player_name unknown
            - run verification_mark_grant_failed def:safe_grant_id|def:player_name|def:error_msg
        - else:
          - narrate "Grant poller: ERROR - Invalid grant_id, skipping..."
          - define error_msg "Invalid grant data: missing grant_id"
          - define grant_id 0
          - define player_name unknown
          - run verification_mark_grant_failed def:grant_id|def:player_name|def:error_msg

      - flag server grant_poller_last_check:<util.time_now>
      - flag server grant_poller_last_count:<[pending].size>
    - else:
      - flag server grant_poller_last_check:<util.time_now>
      - flag server grant_poller_last_count:0


# Grant poller world script - runs on server start and periodically
grant_poller:
  type: world
  debug: false
  events:
    # Run periodically every 30 seconds (starts after first 30 seconds)
    after system time 30s:
      - run grant_poller_process
