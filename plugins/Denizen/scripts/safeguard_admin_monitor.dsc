# safeguard_admin_monitor.dsc
# Admin commands for monitoring and managing two-person safeguarding

# ============================================================================
# COMMAND: /sgaudit [limit]
# View recent safeguarding events from audit log
# ============================================================================
safeguard_audit_command:
  type: command
  name: sgaudit
  aliases:
    - safeguardaudit
    - auditlog
  description: View recent safeguarding events
  usage: /sgaudit [limit]
  permission: minecraftchurch.admin
  script:
    - define limit 20
    - if <context.args.size> > 0:
      - define limit <context.args.get[1]>
    
    - narrate "<&7>Fetching last <&b><[limit]><&7> safeguarding events..."
    
    # Connect to database
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s
    
    # Query for safeguarding events
    - define query "SELECT action_type, target_player, details, created_at FROM audit_log WHERE action_type LIKE 'safeguard_%' ORDER BY created_at DESC LIMIT <[limit]>"
    - ~sql id:db_<queue.id> "query:<[query]>" save:audit_events
    
    # Get results
    - define events <entry[audit_events].result_map>
    - sql disconnect id:db_<queue.id>
    
    - if <[events].size> == 0:
      - narrate "<&7>No safeguarding events found in audit log."
      - stop
    
    # Display events
    - narrate "<&e>━━━ Recent Safeguarding Events ━━━"
    - narrate "<&7>Showing <&b><[events].size><&7> most recent event(s):"
    - narrate ""
    
    - foreach <[events]> as:event:
      - define event_map <[event]>
      - define action <[event_map].get[action_type]>
      - define player <[event_map].get[target_player]>
      - define details <[event_map].get[details]>
      - define timestamp <[event_map].get[created_at]>
      
      # Color code by event type
      - define color <&7>
      - if <[action]> == safeguard_entry_blocked:
        - define color <&c>
        - define action_desc "Entry Blocked"
      - else if <[action]> == safeguard_entry_allowed:
        - define color <&a>
        - define action_desc "Entry Allowed"
      - else if <[action]> == safeguard_supervision_dropped:
        - define color <&c>
        - define action_desc "Supervision Dropped"
      - else if <[action]> == safeguard_supervisor_quit:
        - define color <&c>
        - define action_desc "Supervisor Quit"
      - else:
        - define action_desc <[action]>
      
      - narrate "<[color]>[<[timestamp]>] <&b><[player]><[color]> - <[action_desc]>"
      - narrate "<&7>  Details: <[details]>"
      - narrate ""
    
    - narrate "<&e>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# COMMAND: /sgcheck
# Check all protected regions for current status
# ============================================================================
safeguard_check_all_command:
  type: command
  name: sgcheck
  aliases:
    - checkall
    - safeguardcheck
  description: Check safeguarding status in all protected regions
  usage: /sgcheck
  permission: minecraftchurch.admin
  script:
    - narrate "<&e>━━━ Safeguarding Status: All Protected Regions ━━━"
    
    # Get protected regions from config
    - define protected_regions <script[two_person_config].data_key[regions]>
    - define supervisor_groups <script[two_person_config].data_key[supervisor_groups]>
    - define child_groups <script[two_person_config].data_key[child_groups]>
    - define min_adults <script[two_person_config].data_key[min_adults]>
    
    - define total_violations 0
    - define total_compliant 0
    - define total_empty 0
    
    # Check each region
    - foreach <[protected_regions]> as:region_data:
      # Parse world:region format
      - define parts <[region_data].split[:]>
      - define world_name <[parts].get[1]>
      - define region_id <[parts].get[2]>
      
      # Get world and region
      - define world <server.world[<[world_name]>].if_null[null]>
      - if <[world]> == null:
        - narrate "<&c><[region_data]> - World not found!"
        - foreach next
      
      - define region <[world].cuboid_region[<[region_id]>].if_null[null]>
      - if <[region]> == null:
        - narrate "<&c><[region_data]> - Region not found!"
        - foreach next
      
      # Get players in region
      - define players_in_region <[region].players>
      
      # Count supervisors and children
      - define supervisor_count 0
      - define child_count 0
      
      - foreach <[players_in_region]> as:p:
        - define p_group <[p].groups.first.if_null[guest]>
        - if <[supervisor_groups].contains[<[p_group]>]>:
          - define supervisor_count <[supervisor_count].add[1]>
        - if <[child_groups].contains[<[p_group]>]>:
          - define child_count <[child_count].add[1]>
      
      # Determine status
      - if <[child_count]> == 0:
        - narrate "<&7><[region_data]> - Empty (no children)"
        - define total_empty <[total_empty].add[1]>
      - else:
        - if <[supervisor_count]> >= <[min_adults]>:
          - narrate "<&a><[region_data]> - ✓ COMPLIANT (<[supervisor_count]> supervisors, <[child_count]> children)"
          - define total_compliant <[total_compliant].add[1]>
        - else:
          - narrate "<&c><[region_data]> - ⚠ VIOLATION (<[supervisor_count]>/<[min_adults]> supervisors, <[child_count]> children)"
          - define total_violations <[total_violations].add[1]>
    
    # Summary
    - narrate ""
    - narrate "<&e>━━━ Summary ━━━"
    - narrate "<&7>Total protected regions: <&b><[protected_regions].size>"
    - narrate "<&a>Compliant: <&b><[total_compliant]>"
    - narrate "<&c>Violations: <&b><[total_violations]>"
    - narrate "<&7>Empty: <&b><[total_empty]>"
    
    - if <[total_violations]> > 0:
      - narrate ""
      - narrate "<&c>⚠ WARNING: <[total_violations]> region(s) have safeguarding violations!"
      - narrate "<&7>Use <&b>/safeguard status <region><&7> for details"

# ============================================================================
# COMMAND: /sgalert [on|off]
# Toggle safeguarding alerts for this admin
# ============================================================================
safeguard_alert_toggle_command:
  type: command
  name: sgalert
  aliases:
    - safeguardalert
  description: Toggle safeguarding alert notifications
  usage: /sgalert [on|off]
  permission: minecraftchurch.admin
  script:
    - if <context.args.size> < 1:
      # Check current status
      - define current_status <player.has_flag[safeguard_alerts]>
      - if <[current_status]>:
        - narrate "<&7>Safeguarding alerts: <&a>ENABLED"
        - narrate "<&7>Use <&b>/sgalert off<&7> to disable"
      - else:
        - narrate "<&7>Safeguarding alerts: <&c>DISABLED"
        - narrate "<&7>Use <&b>/sgalert on<&7> to enable"
      - stop
    
    - define mode <context.args.get[1].to_lowercase>
    
    - if <[mode]> == on:
      - flag player safeguard_alerts
      - narrate "<&a>✓ Safeguarding alerts ENABLED"
      - narrate "<&7>You will now receive notifications about all safeguarding events."
    - else if <[mode]> == off:
      - flag player safeguard_alerts:!
      - narrate "<&c>✓ Safeguarding alerts DISABLED"
      - narrate "<&7>You will no longer receive safeguarding notifications."
    - else:
      - narrate "<&c>Usage: /sgalert [on|off]"

# ============================================================================
# COMMAND: /sgsession [region]
# View current active sessions (children with supervisors)
# ============================================================================
safeguard_session_command:
  type: command
  name: sgsession
  aliases:
    - sessions
    - activesessions
  description: View active supervision sessions
  usage: /sgsession [region]
  permission: minecraftchurch.admin
  script:
    - narrate "<&e>━━━ Active Supervision Sessions ━━━"
    
    # Get protected regions from config
    - define protected_regions <script[two_person_config].data_key[regions]>
    - define supervisor_groups <script[two_person_config].data_key[supervisor_groups]>
    - define child_groups <script[two_person_config].data_key[child_groups]>
    
    - define active_sessions 0
    
    # Check each region for active sessions
    - foreach <[protected_regions]> as:region_data:
      # Parse world:region format
      - define parts <[region_data].split[:]>
      - define world_name <[parts].get[1]>
      - define region_id <[parts].get[2]>
      
      # Get world and region
      - define world <server.world[<[world_name]>].if_null[null]>
      - if <[world]> == null:
        - foreach next
      
      - define region <[world].cuboid_region[<[region_id]>].if_null[null]>
      - if <[region]> == null:
        - foreach next
      
      # Get players in region
      - define players_in_region <[region].players>
      
      # Count supervisors and children
      - define supervisors_list <list[]>
      - define children_list <list[]>
      
      - foreach <[players_in_region]> as:p:
        - define p_group <[p].groups.first.if_null[guest]>
        - if <[supervisor_groups].contains[<[p_group]>]>:
          - define supervisors_list <[supervisors_list].include[<[p].name>_(<[p_group]>)]>
        - if <[child_groups].contains[<[p_group]>]>:
          - define children_list <[children_list].include[<[p].name>]>
      
      # Only show if children are present (active session)
      - if <[children_list].size> > 0:
        - define active_sessions <[active_sessions].add[1]>
        - narrate ""
        - narrate "<&b>Region: <&e><[region_data]>"
        - narrate "<&7>  Supervisors (<&b><[supervisors_list].size><&7>):"
        - foreach <[supervisors_list]> as:sup:
          - narrate "<&7>    - <[sup]>"
        - narrate "<&7>  Children (<&b><[children_list].size><&7>):"
        - foreach <[children_list]> as:kid:
          - narrate "<&7>    - <[kid]>"
    
    - if <[active_sessions]> == 0:
      - narrate ""
      - narrate "<&7>No active supervision sessions found."
    - else:
      - narrate ""
      - narrate "<&e>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      - narrate "<&7>Total active sessions: <&b><[active_sessions]>"

# ============================================================================
# COMMAND: /sgstats
# View safeguarding statistics
# ============================================================================
safeguard_stats_command:
  type: command
  name: sgstats
  aliases:
    - safeguardstats
  description: View safeguarding statistics
  usage: /sgstats
  permission: minecraftchurch.admin
  script:
    - narrate "<&7>Fetching safeguarding statistics..."
    
    # Connect to database
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s
    
    # Get counts by event type (last 30 days)
    - define query_blocked "SELECT COUNT(*) as count FROM audit_log WHERE action_type='safeguard_entry_blocked' AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)"
    - define query_allowed "SELECT COUNT(*) as count FROM audit_log WHERE action_type='safeguard_entry_allowed' AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)"
    - define query_dropped "SELECT COUNT(*) as count FROM audit_log WHERE action_type='safeguard_supervision_dropped' AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)"
    - define query_quit "SELECT COUNT(*) as count FROM audit_log WHERE action_type='safeguard_supervisor_quit' AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)"
    
    - ~sql id:db_<queue.id> "query:<[query_blocked]>" save:blocked_result
    - define blocked_count <entry[blocked_result].result_map.get[1].get[count].if_null[0]>
    
    - ~sql id:db_<queue.id> "query:<[query_allowed]>" save:allowed_result
    - define allowed_count <entry[allowed_result].result_map.get[1].get[count].if_null[0]>
    
    - ~sql id:db_<queue.id> "query:<[query_dropped]>" save:dropped_result
    - define dropped_count <entry[dropped_result].result_map.get[1].get[count].if_null[0]>
    
    - ~sql id:db_<queue.id> "query:<[query_quit]>" save:quit_result
    - define quit_count <entry[quit_result].result_map.get[1].get[count].if_null[0]>
    
    - sql disconnect id:db_<queue.id>
    
    # Display statistics
    - narrate "<&e>━━━ Safeguarding Statistics (Last 30 Days) ━━━"
    - narrate ""
    - narrate "<&7>Entry Events:"
    - narrate "<&a>  ✓ Allowed entries: <&b><[allowed_count]>"
    - narrate "<&c>  ✗ Blocked entries: <&b><[blocked_count]>"
    - narrate ""
    - narrate "<&7>Supervision Events:"
    - narrate "<&c>  ⚠ Supervision dropped (exit): <&b><[dropped_count]>"
    - narrate "<&c>  ⚠ Supervisor quit (disconnect): <&b><[quit_count]>"
    - narrate ""
    - define total_events <[allowed_count].add[<[blocked_count]>].add[<[dropped_count]>].add[<[quit_count]>]>
    - narrate "<&7>Total safeguarding events: <&b><[total_events]>"
    - narrate "<&e>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
