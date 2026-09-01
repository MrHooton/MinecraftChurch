# admin_approval.dsc
# Admin commands for approving/rejecting verification requests and managing grants

# Command: /approve <request_id> [notes]
# Approves a verification request and creates access grants
approve_request_command:
  type: command
  name: approve
  description: Approve a verification request and create access grants
  usage: /approve [request_id] [notes]
  permission: minecraftchurch.admin
  script:
    - if <context.args.size> < 1:
      - narrate "<&c>Usage: /approve [request_id] [notes]"
      - narrate "<&7>Example: /approve 5"
      - narrate "<&7>Example: /approve 5 Approved by admin"
      - determine cancelled
    - define request_id <context.args.get[1]>
    - define admin_name <player.name>
    - define notes ""
    - if <context.args.size> > 1:
      - define notes <context.args.get[2].to[<context.args.size>].join[ ]>
    - narrate "<&7>Approving request #<[request_id]>..."
    # FIX: Correct def passing (single def: with | separators)
    - run verification_approve_request def:<[request_id]>|<[admin_name]>|<[notes]>

# Command: /reject <request_id> <reason>
# Rejects a verification request
reject_request_command:
  type: command
  name: reject
  description: Reject a verification request
  usage: /reject [request_id] [reason]
  permission: minecraftchurch.admin
  script:
    - if <context.args.size> < 2:
      - narrate "<&c>Usage: /reject [request_id] [reason]"
      - narrate "<&7>Example: /reject 5 Invalid code"
      - determine cancelled
    - define request_id <context.args.get[1]>
    - define admin_name <player.name>
    - define reason <context.args.get[2].to[<context.args.size>].join[ ]>
    - narrate "<&7>Rejecting request #<[request_id]>..."
    # FIX: Correct def passing
    - run verification_reject_request def:<[request_id]>|<[admin_name]>|<[reason]>

# Command: /pending
# Lists all pending verification requests
list_pending_command:
  type: command
  name: pending
  description: List all pending verification requests
  usage: /pending
  permission: minecraftchurch.admin
  script:
    - define admin_name <player.name>
    - narrate "<&7>Fetching pending requests..."
    # FIX: Correct def passing
    - run verification_list_pending def:<[admin_name]>

# Command: /view <request_id>
# View details of a specific verification request
view_request_command:
  type: command
  name: view
  description: View details of a specific verification request
  usage: /view [request_id]
  permission: minecraftchurch.admin
  script:
    - if <context.args.size> < 1:
      - narrate "<&c>Usage: /view [request_id]"
      - narrate "<&7>Example: /view 6"
      - determine cancelled
    - define request_id <context.args.get[1]>
    - narrate "<&7>Fetching request #<[request_id]>..."
    # FIX: Correct def passing
    - run verification_view_request def:<[request_id]>

# Command: /list [status]
# Lists all verification requests (or filter by status)
list_all_command:
  type: command
  name: requests
  aliases: verificationrequests|vrequests
  description: List all verification requests, optionally filtered by status
  usage: /requests [status]
  permission: minecraftchurch.admin
  script:
    - if <context.source_type> != player:
      - narrate "<&c>Run this command in-game."
      - determine cancelled
    - define admin_name <player.name>
    - define status_filter ""
    - if <context.args.size> > 0:
      - define status_filter <context.args.get[1]>
    - narrate "<&7>Fetching requests..."
    # FIX: Correct def passing
    - run verification_list_all def:<[admin_name]>|<[status_filter]>

# Command: /createrequest <child_name> <code> <parent_name> <parent_email> [adult_name] [church]
# Creates a verification request in-game (for testing or direct submission)
create_request_command:
  type: command
  name: createrequest
  aliases: submitrequest|newrequest
  description: Create a verification request in-game
  usage: /createrequest [child_name] [code] [parent_name] [parent_email] [adult_name] [church]
  permission: minecraftchurch.admin
  script:
    - if <context.args.size> < 4:
      - narrate "<&c>Usage: /createrequest [child_name] [code] [parent_name] [parent_email] [adult_name] [church]"
      - narrate "<&7>Example: /createrequest PlayerName ABC123 JohnDoe john@example.com"
      - narrate "<&7>Example: /createrequest PlayerName ABC123 JohnDoe john@example.com ParentName FirstChurch"
      - determine cancelled
    - define child_name <context.args.get[1]>
    - define code <context.args.get[2]>
    - define parent_name <context.args.get[3]>
    - define parent_email <context.args.get[4]>
    - define adult_name ""
    - define church ""
    - if <context.args.size> > 4:
      - define adult_name <context.args.get[5]>
    - if <context.args.size> > 5:
      - define church <context.args.get[6].to[<context.args.size>].join[ ]>
    - narrate "<&7>Creating verification request for <[child_name]>..."
    - run verification_create_request def:<[child_name]>|<[code]>|<[parent_name]>|<[parent_email]>|<[adult_name]>|<[church]>

# Task: Approve a verification request
verification_approve_request:
  type: task
  definitions: request_id|admin_name|notes
  script:
    # Connect to database
    # Try to disconnect first to avoid conflicts (fails silently if not connected)
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s

    # First, verify the request exists and is pending
    - define check_query "SELECT * FROM verification_requests WHERE id=<[request_id]> AND status='pending'"
    - ~sql id:db_<queue.id> "query:<[check_query]>" save:request_check
    - define request_data <entry[request_check].result_map>

    - if <[request_data].size> == 0:
      - narrate "<&c>Error: Request #<[request_id]> not found or already processed!"
      - sql disconnect id:db_<queue.id>
      - determine false

    - define request_map <[request_data].get[1]>
    - define child_name <[request_map].get[child_name]>
    - define adult_name <[request_map].get[adult_name]>
    - define code <[request_map].get[code]>

    # Escape notes for SQL (minimal quote escape)
    - define notes_escaped <[notes].if_null[].replace[']][\\']>

    # Update request status to approved
    - define update_request_query "UPDATE verification_requests SET status='approved', approved_by='<[admin_name]>', approved_at=NOW(), notes='<[notes_escaped]>' WHERE id=<[request_id]>"
    - ~sql id:db_<queue.id> "update:<[update_request_query]>"
    - narrate "<&a>Request #<[request_id]> marked as approved"

    # Create access grant for child (always created)
    - define child_grant_query "INSERT INTO access_grants (request_id, player_name, grant_type, grant_value, status) VALUES (<[request_id]>, '<[child_name]>', 'group', 'child', 'approved')"
    - ~sql id:db_<queue.id> "update:<[child_grant_query]>"
    - narrate "<&a>Created child grant for <[child_name]> (group: child)"

    # Create access grant for adult if adult_name exists
    - if <[adult_name].length> > 0:
      - define adult_grant_query "INSERT INTO access_grants (request_id, player_name, grant_type, grant_value, status) VALUES (<[request_id]>, '<[adult_name]>', 'group', 'adult', 'approved')"
      - ~sql id:db_<queue.id> "update:<[adult_grant_query]>"
      - narrate "<&a>Created adult grant for <[adult_name]> (group: adult)"

    # Log to audit_log
    - define audit_query "INSERT INTO audit_log (action_type, admin_user, target_player, request_id, details, created_at) VALUES ('request_approved', '<[admin_name]>', '<[child_name]>', <[request_id]>, '{\"notes\":\"<[notes_escaped]>\"}', NOW())"
    - ~sql id:db_<queue.id> "update:<[audit_query]>"

    - narrate "<&a>✓ Request #<[request_id]> approved successfully!"
    - narrate "<&7>Grants will be applied automatically by the poller within 30 seconds."
    - sql disconnect id:db_<queue.id>
    - determine true

# Task: Reject a verification request
verification_reject_request:
  type: task
  definitions: request_id|admin_name|reason
  script:
    # Connect to database
    # Try to disconnect first to avoid conflicts (fails silently if not connected)
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s

    # Verify the request exists and is pending
    - define check_query "SELECT * FROM verification_requests WHERE id=<[request_id]> AND status='pending'"
    - ~sql id:db_<queue.id> "query:<[check_query]>" save:request_check
    - define request_data <entry[request_check].result_map>

    - if <[request_data].size> == 0:
      - narrate "<&c>Error: Request #<[request_id]> not found or already processed!"
      - sql disconnect id:db_<queue.id>
      - determine false

    - define request_map <[request_data].get[1]>
    - define child_name <[request_map].get[child_name]>

    # Escape reason for SQL (minimal quote escape)
    - define reason_escaped <[reason].if_null[].replace[']][\\']>

    # Update request status to rejected
    - define update_request_query "UPDATE verification_requests SET status='rejected', approved_by='<[admin_name]>', approved_at=NOW(), notes='<[reason_escaped]>' WHERE id=<[request_id]>"
    - ~sql id:db_<queue.id> "update:<[update_request_query]>"

    # Log to audit_log
    - define audit_query "INSERT INTO audit_log (action_type, admin_user, target_player, request_id, details, created_at) VALUES ('request_rejected', '<[admin_name]>', '<[child_name]>', <[request_id]>, '{\"reason\":\"<[reason_escaped]>\"}', NOW())"
    - ~sql id:db_<queue.id> "update:<[audit_query]>"

    - narrate "<&c>Request #<[request_id]> rejected: <[reason]>"
    - sql disconnect id:db_<queue.id>
    - determine true

# Task: List pending verification requests
verification_list_pending:
  type: task
  definitions: admin_name
  script:
    # Connect to database
    # Try to disconnect first to avoid conflicts (fails silently if not connected)
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s

    # Query for pending requests
    - define query "SELECT * FROM verification_requests WHERE status='pending' ORDER BY created_at ASC LIMIT 20"
    - ~sql id:db_<queue.id> "query:<[query]>" save:pending_requests

    # Get the results
    - define requests <entry[pending_requests].result_map>
    - sql disconnect id:db_<queue.id>

    - if <[requests].size> == 0:
      - narrate "<&7>No pending requests found."
      - determine <list[]>

    - narrate "<&e>=== Pending Verification Requests ==="
    - narrate "<&7>Found <[requests].size]> pending request(s):"
    - narrate ""
    - foreach <[requests]> as:req:
      - define req_map <[req]>
      - define req_id <[req_map].get[id]>
      - define child <[req_map].get[child_name]>
      - define parent <[req_map].get[parent_name]>
      - define email <[req_map].get[parent_email]>
      - define code <[req_map].get[code]>
      - define created <[req_map].get[created_at]>
      - define adult <[req_map].get[adult_name]>
      - narrate "<&e>━━━ Request ID: <&b><&bold><[req_id]><&r><&e> ━━━"
      - narrate "<&7>Child: <&b><[child]>"
      - narrate "<&7>Parent: <&b><[parent]>"
      - narrate "<&7>Email: <&b><[email]>"
      - narrate "<&7>Code: <&b><[code]>"
      - if <[adult].length> > 0:
        - narrate "<&7>Adult joining: <&b><[adult]>"
      - narrate "<&7>Submitted: <&b><[created]>"
      - narrate "<&a>→ Approve: <&b>/approve <[req_id]>"
      - narrate "<&c>→ Reject: <&b>/reject <[req_id]> [reason]"
      - narrate ""

    - determine <[requests]>

# Task: List all verification requests (optionally filtered by status)
verification_list_all:
  type: task
  definitions: admin_name|status_filter
  script:
    # Connect to database
    # Try to disconnect first to avoid conflicts (fails silently if not connected)
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s

    # Build query based on status filter
    - define filter_value <[status_filter].if_null[]>
    - define has_filter <[filter_value].length.is_more_than[0]>

    # Debug logs (compat: use announce to_console - older Denizen log syntax differs)
    - define debug_msg "DEBUG: status_filter value is: <[filter_value]> (length: <[filter_value].length>)"
    - announce "<&7><[debug_msg]>" to_console
    - if <[has_filter]>:
      - define debug_msg2 "DEBUG: Using filter: <[filter_value]>"
      - announce "<&7><[debug_msg2]>" to_console
    - else:
      - announce "<&7>DEBUG: No filter, showing all requests" to_console

    - if <[has_filter]>:
      - define query "SELECT * FROM verification_requests WHERE status='<[filter_value]>' ORDER BY created_at DESC LIMIT 50"
    - else:
      - define query "SELECT * FROM verification_requests ORDER BY created_at DESC LIMIT 50"
    - ~sql id:db_<queue.id> "query:<[query]>" save:all_requests

    # Get the results
    - define requests <entry[all_requests].result_map>
    - sql disconnect id:db_<queue.id>

    - if <[requests].size> == 0:
      - if <[has_filter]>:
        - narrate "<&7>No requests found with status '<[filter_value]>'."
      - else:
        - narrate "<&7>No requests found."
      - determine <list[]>

    # Display header
    - if <[has_filter]>:
      - narrate "<&e>=== Verification Requests (Status: <[filter_value]>) ==="
    - else:
      - narrate "<&e>=== All Verification Requests ==="
    - narrate "<&7>Found <[requests].size]> request(s):"
    - narrate ""
    - foreach <[requests]> as:req:
      - define req_map <[req]>
      - define req_id <[req_map].get[id]>
      - define child <[req_map].get[child_name]>
      - define parent <[req_map].get[parent_name]>
      - define email <[req_map].get[parent_email]>
      - define code <[req_map].get[code]>
      - define status <[req_map].get[status]>
      - define created <[req_map].get[created_at]>
      - define adult <[req_map].get[adult_name]>
      - define approved_by <[req_map].get[approved_by]>

      # Color code status
      - define status_color <&7>
      - if <[status].equals[pending]>:
        - define status_color <&e>
      - else if <[status].equals[approved]>:
        - define status_color <&a>
      - else if <[status].equals[rejected]>:
        - define status_color <&c>

      - narrate "<&e>━━━ Request ID: <&b><&bold><[req_id]><&r><&e> ━━━"
      - narrate "<&7>Status: <[status_color]><[status]>"
      - narrate "<&7>Child: <&b><[child]>"
      - narrate "<&7>Parent: <&b><[parent]>"
      - narrate "<&7>Email: <&b><[email]>"
      - narrate "<&7>Code: <&b><[code]>"
      - if <[adult].length> > 0:
        - narrate "<&7>Adult joining: <&b><[adult]>"
      - narrate "<&7>Submitted: <&b><[created]>"
      - if <[approved_by].length> > 0:
        - narrate "<&7>Processed by: <&b><[approved_by]>"
      - narrate "<&7>→ View: <&b>/view <[req_id]>"
      - if <[status].equals[pending]>:
        - narrate "<&a>→ Approve: <&b>/approve <[req_id]>"
        - narrate "<&c>→ Reject: <&b>/reject <[req_id]> [reason]"
      - narrate ""

    - determine <[requests]>

# Task: View a specific verification request
verification_view_request:
  type: task
  definitions: request_id
  script:
    # Connect to database
    # Try to disconnect first to avoid conflicts (fails silently if not connected)
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s

    # Query for the specific request
    - define query "SELECT * FROM verification_requests WHERE id=<[request_id]>"
    - ~sql id:db_<queue.id> "query:<[query]>" save:request_data

    # Get the results
    - define requests <entry[request_data].result_map>
    - sql disconnect id:db_<queue.id>

    - if <[requests].size> == 0:
      - narrate "<&c>Request #<[request_id]> not found!"
      - determine false

    - define req_map <[requests].get[1]>
    - define req_id <[req_map].get[id]>
    - define child <[req_map].get[child_name]>
    - define adult <[req_map].get[adult_name]>
    - define parent <[req_map].get[parent_name]>
    - define email <[req_map].get[parent_email]>
    - define code <[req_map].get[code]>
    - define status <[req_map].get[status]>
    - define created <[req_map].get[created_at]>
    - define approved_by <[req_map].get[approved_by]>
    - define approved_at <[req_map].get[approved_at]>
    - define notes <[req_map].get[notes]>

    - narrate "<&e>━━━ Request Details ━━━"
    - narrate "<&7>Request ID: <&b><&bold><[req_id]>"
    - narrate "<&7>Status: <&b><[status]>"
    - narrate "<&7>Child: <&b><[child]>"
    - narrate "<&7>Parent: <&b><[parent]>"
    - narrate "<&7>Email: <&b><[email]>"
    - narrate "<&7>Code: <&b><[code]>"
    - if <[adult].length> > 0:
      - narrate "<&7>Adult joining: <&b><[adult]>"
    - narrate "<&7>Created: <&b><[created]>"
    - if <[approved_by].length> > 0:
      - narrate "<&7>Approved by: <&b><[approved_by]>"
      - narrate "<&7>Approved at: <&b><[approved_at]>"
    - if <[notes].length> > 0:
      - narrate "<&7>Notes: <&b><[notes]>"

    - if <[status].equals[pending]>:
      - narrate ""
      - narrate "<&a>→ Approve: <&b>/approve <[req_id]>" 
      - narrate "<&c>→ Reject: <&b>/reject <[req_id]> [reason]"

    - determine true

# Task: Create a verification request
verification_create_request:
  type: task
  definitions: child_name|code|parent_name|parent_email|adult_name|church
  script:
    # Connect to database
    # Try to disconnect first to avoid conflicts (fails silently if not connected)
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s

    # Verify code exists and is valid
    # Use SQL to compute expiry to avoid Denizen time parsing / column casing issues.
    - define code_check_query "SELECT code, child_name, used_at, IF(expires_at IS NULL, 1, 0) AS exp_missing, DATE_FORMAT(COALESCE(expires_at, DATE_ADD(created_at, INTERVAL 15 MINUTE)), '%Y-%m-%d %H:%i:%s') AS expires_at_str, IF(COALESCE(expires_at, DATE_ADD(created_at, INTERVAL 15 MINUTE)) < NOW(), 1, 0) AS is_expired FROM verification_codes WHERE code='<[code]>'"
    - ~sql id:db_<queue.id> "query:<[code_check_query]>" save:code_check
    - define code_data <entry[code_check].result_map>

    - if <[code_data].size> == 0:
      - narrate "<&c>Error: Verification code '<[code]>' not found!"
      - sql disconnect id:db_<queue.id>
      - determine false

    - define code_map <[code_data].get[1]>
    # Some Denizen/MySQL combos may return column keys in different casing.
    - define code_child_name <[code_map].get[child_name].if_null[<[code_map].get[CHILD_NAME].if_null[]>]>
    - define used_at <[code_map].get[used_at].if_null[<[code_map].get[USED_AT].if_null[]>]>
    - define exp_missing <[code_map].get[exp_missing].if_null[<[code_map].get[EXP_MISSING].if_null[0]>]>
    - define expires_at_str <[code_map].get[expires_at_str].if_null[<[code_map].get[EXPIRES_AT_STR].if_null[]>]>
    - define is_expired <[code_map].get[is_expired].if_null[<[code_map].get[IS_EXPIRED].if_null[0]>]>

    # Check if code matches child name (case-insensitive)
    - if !<[code_child_name].equals_ignorecase[<[child_name]>]>:
      - narrate "<&c>Error: Code '<[code]>' does not match child name '<[child_name]>' (code belongs to '<[code_child_name]>')"
      - sql disconnect id:db_<queue.id>
      - determine false

    # Check expiration using SQL-derived fields
    - if <[exp_missing]> == 1:
      - narrate "<&c>Error: Verification code '<[code]>' has no expiration date!"
      - sql disconnect id:db_<queue.id>
      - determine false
    - if <[is_expired]> == 1:
      - narrate "<&c>Error: Verification code '<[code]>' has expired! (expired at: <[expires_at_str]>)"
      - sql disconnect id:db_<queue.id>
      - determine false

    # Check if code is already used
    - if <[used_at].is_not_empty>:
      - narrate "<&c>Error: Verification code '<[code]>' has already been used!"
      - sql disconnect id:db_<queue.id>
      - determine false

    # Get client IP (use server IP or placeholder for in-game creation)
    - define client_ip "127.0.0.1"

    # Start transaction: mark code as used and create request
    # Mark code as used
    - define update_code_query "UPDATE verification_codes SET used_at=NOW(), used_by_email='<[parent_email]>', used_ip='<[client_ip]>' WHERE code='<[code]>'"
    - ~sql id:db_<queue.id> "update:<[update_code_query]>"

    # Escape values for SQL
    - define parent_name_escaped <[parent_name].replace[']][\\']>
    - define parent_email_escaped <[parent_email].replace[']][\\']>
    - define church_escaped <[church].if_null[].replace[']][\\']>

    # Determine adult_join (1 if adult_name provided, 0 otherwise)
    - define adult_join 0
    - if <[adult_name].length> > 0:
      - define adult_join 1
      - define adult_name_escaped <[adult_name].replace[']][\\']>
      - define adult_name_value "'<[adult_name_escaped]>'"
    - else:
      - define adult_name_value "NULL"

    # Create verification request (handle NULL for adult_name and church)
    - define church_value "'<[church_escaped]>'"
    - if <[church].length> == 0:
      - define church_value "NULL"
    - define insert_query "INSERT INTO verification_requests (child_name, adult_name, code, parent_name, parent_email, consent, church, adult_join, status) VALUES ('<[child_name]>', <[adult_name_value]>, '<[code]>', '<[parent_name_escaped]>', '<[parent_email_escaped]>', 1, <[church_value]>, <[adult_join]>, 'pending')"
    - ~sql id:db_<queue.id> "update:<[insert_query]>"

    # Get the request ID by querying for the request we just created
    - wait 1s
    - define get_id_query "SELECT id FROM verification_requests WHERE code='<[code]>' AND child_name='<[child_name]>' AND status='pending' ORDER BY created_at DESC LIMIT 1"
    - ~sql id:db_<queue.id> "query:<[get_id_query]>" save:request_id_result
    - define request_id_data <entry[request_id_result].result_map>
    - if <[request_id_data].size> == 0:
      - narrate "<&c>Error: Failed to retrieve request ID after creation!"
      - sql disconnect id:db_<queue.id>
      - determine false
    - define request_id_map <[request_id_data].get[1]>
    - define request_id <[request_id_map].get[id]>

    - narrate "<&a>✓ Verification request created successfully!"
    - narrate "<&7>Request ID: <&b><[request_id]>"
    - narrate "<&7>Child: <&b><[child_name]>"
    - narrate "<&7>Parent: <&b><[parent_name]>"
    - narrate "<&7>Status: <&e>pending"
    - narrate "<&7>Use <&b>/view <[request_id]><&7> to view details"
    - narrate "<&7>Use <&b>/approve <[request_id]><&7> to approve"

    - sql disconnect id:db_<queue.id>
    - determine true
