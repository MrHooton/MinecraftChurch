# two_person_safeguard.dsc
# Enforces two-person safeguarding rule in spiritual direction spaces
# Prevents children from being alone with a single adult

# ============================================================================
# CONFIGURATION
# ============================================================================
# Two-person rule can be enforced at REGION level or WORLD level
#
# REGIONS: Specific regions that require supervision
#   Format: world_name:region_name
#   Example: - Minecraft Church:room7
#
# WORLDS: Entire worlds that require supervision (recommended for "most worlds")
#   Format: just the world name
#   Example: - sd
#
two_person_config:
  type: data
  # Specific regions requiring two-person supervision
  regions:
    - Minecraft Church:room7
    - Minecraft_Church:room7
    - sd:sd
    - sd:sd2
    - SD2:sd2
  # Entire worlds requiring two-person supervision (enforced everywhere in world)
  protected_worlds:
    - sd
    - homes
    - sheep
    - village
    - GoodShepherd
  # Worlds that require vetting: ONLY director/observer/child may be present
  # (Children only allowed when supervised per min_adults)
  vetted_only_worlds:
    - sd
  # Worlds where NO supervision required (safe/public areas)
  exempt_worlds:
    - Minecraft Church
    - Minecraft_Church
  # Minimum adults required when children are present
  min_adults: 2
  # Groups that count as "supervising adults"
  supervisor_groups:
    - director
    - observer
  # Groups that count as "children requiring supervision"
  child_groups:
    - child
  # Groups allowed inside vetted worlds (spiritual direction spaces)
  vetted_allowed_groups:
    - director
    - observer
    - child
  # Enable audit logging
  audit_logging: true

# ============================================================================
# FOYER / APPROACH BOUNDARY LAYER (Optional)
# ============================================================================
# This adds a physical "foyer" (approach) area and an inner "denied boundary".
#
# How it works:
# - Admin defines 2 cuboids per world via /sgfoyer:
#   - foyer: where players get greeted/instructed
#   - denied: inner area children may not cross unless supervision is adequate
# - If a child tries to cross into denied cuboid without enough supervisors,
#   they are teleported back to a configured "return" location (usually in foyer).
#
# Locations are stored as server flags:
# - sg_foyer.<world>.foyer_pos1 / foyer_pos2
# - sg_foyer.<world>.denied_pos1 / denied_pos2
# - sg_foyer.<world>.return_loc
# - sg_foyer.<world>.npc_loc (optional)
# - sg_foyer.<world>.sign_loc (optional)
#
# Greeting text is configurable here.
two_person_foyer_config:
  type: data
  enabled: true
  # How often to re-greet a player when re-entering the foyer (per-world).
  greet_cooldown: 2m
  greeting:
    - "<&6>Welcome to the Spiritual Direction foyer."
    - "<&7>For child safety, access beyond this point requires <&b>2 vetted supervisors<&7> (director/observer)."
    - "<&7>If you’re a child, please wait here until supervisors are present."

# ============================================================================
# WORLD SCRIPT - Active Monitoring
# ============================================================================
two_person_safeguard_monitor:
  type: world
  debug: false
  events:
    # NOTE: Region-level monitoring disabled due to Denizen compatibility issues
    # Using world-level monitoring + periodic checks instead
    
    # Monitor world join and teleport (for ejection after entry)
on player joins:
  wait 5t
  if <player.world.name> != Minecraft_Church:
    stop

      - run two_person_world_monitor
    
    # Try to intercept mvtp command
    on mvtp command:
      - announce "<&7>[DEBUG] MVTP command detected from <player.name>" to_console
      - if <context.args.size> < 1:
        - stop
      - define target_world <context.args.get[1]>
      - announce "<&7>[DEBUG] Target world: <[target_world]>" to_console
      
      # Check if target world is protected
      - define protected_worlds <script[two_person_config].data_key[protected_worlds]>
      - define vetted_only_worlds <script[two_person_config].data_key[vetted_only_worlds]>
      - if !<[protected_worlds].contains[<[target_world]>]>:
        - announce "<&7>[DEBUG] World not protected, allowing" to_console
        - stop
      
      # Get player's group from database
      - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
      - wait 1t
      - define player_name <player.name>
      - define perm_query "SELECT permission_level FROM known_players WHERE player_name='<[player_name]>' LIMIT 1"
      - ~sql id:db_<queue.id> "query:<[perm_query]>" save:perm_result
      - define perm_rows <entry[perm_result].result_map>
      - define player_group guest
      - if <[perm_rows].size> > 0:
        - define player_group <[perm_rows].get[1].get[permission_level].if_null[guest]>
      - sql disconnect id:db_<queue.id>
      
      - announce "<&7>[DEBUG] Player group: <[player_group]>" to_console

      # If this is a vetted-only world, block non-vetted roles from entering at all.
      - if <[vetted_only_worlds].contains[<[target_world]>]>:
        - define vetted_allowed <script[two_person_config].data_key[vetted_allowed_groups]>
        - if !<[vetted_allowed].contains[<[player_group]>]>:
          - determine cancelled
          - narrate "<&c>Access Denied"
          - narrate "<&7>This spiritual direction world is restricted to <&b>director<&7>/<&b>observer<&7> (vetted staff) and supervised <&b>children<&7>."
          - announce "<&7>[DEBUG] Command BLOCKED (non-vetted role '<[player_group]>')" to_console
          - stop
      
      # Check if player is a child
      - define child_groups <script[two_person_config].data_key[child_groups]>
      - if !<[child_groups].contains[<[player_group]>]>:
        - announce "<&7>[DEBUG] Player is not a child, allowing" to_console
        - stop
      
      # Player is a child trying to enter protected world - count supervisors
      - announce "<&7>[DEBUG] Child attempting protected world, checking supervisors..." to_console
      - define supervisor_count 0
      - define supervisor_groups <script[two_person_config].data_key[supervisor_groups]>
      - define min_adults <script[two_person_config].data_key[min_adults]>
      
      # Find target world
      - define target_world_obj null
      - foreach <server.worlds> as:w:
        - if <[w].name> == <[target_world]>:
          - define target_world_obj <[w]>
          - foreach stop
      
      - if <[target_world_obj]> == null:
        - announce "<&7>[DEBUG] Target world not found" to_console
        - stop
      
      # Count supervisors in target world
      - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
      - wait 1t
      - foreach <[target_world_obj].players> as:p:
        - define p_name <[p].name>
        - define p_query "SELECT permission_level FROM known_players WHERE player_name='<[p_name]>' LIMIT 1"
        - ~sql id:db_<queue.id> "query:<[p_query]>" save:p_result
        - define p_rows <entry[p_result].result_map>
        - if <[p_rows].size> > 0:
          - define p_group <[p_rows].get[1].get[permission_level].if_null[guest]>
          - if <[supervisor_groups].contains[<[p_group]>]>:
            - define supervisor_count <[supervisor_count].add[1]>
      - sql disconnect id:db_<queue.id>
      
      - announce "<&7>[DEBUG] Supervisor count in target: <[supervisor_count]>" to_console
      
      # Check if adequate supervision
      - if <[supervisor_count]> < <[min_adults]>:
        # Block the teleport
        - determine cancelled
        - narrate "<&c>⚠ SAFEGUARDING: Access Denied"
        - narrate "<&7>World <&b><[target_world]><&7> requires <&b><[min_adults]> supervising adults<&7> (director/observer) for child access."
        - narrate "<&7>Currently present: <&b><[supervisor_count]> supervisor(s)<&7>."
        - narrate "<&7>Please wait for adequate supervision before entering."
        - announce "<&7>[DEBUG] Command BLOCKED due to insufficient supervision" to_console
      - else:
        - announce "<&7>[DEBUG] Adequate supervision, allowing teleport" to_console
    
    # Fallback: eject after teleport if command interception doesn't work
    on player teleports:
      - wait 2t
      - run two_person_world_monitor
    
    # Start background monitor when server starts
    on server start:
      - run safeguard_background_monitor
    
    # Monitor when players quit (could leave children unsupervised)
    on player quits:
      - foreach <script[two_person_config].data_key[regions]> as:region_data:
        - define parts <[region_data].split[:]>
        - define world_name <[parts].get[1]>
        - define region_id <[parts].get[2]>
        
        # Check if quitting player was in a protected region
        - if <player.world.name> == <[world_name]>:
          - define region <player.world.cuboid_region[<[region_id]>].if_null[null]>
          - if <[region]> != null:
            - if <[region].contains_location[<player.location>]>:
              # Player was in protected region, check remaining supervision
              - wait 1t
              - run two_person_check_quit def:<player.name>|<[region_id]>|<[world_name]>

    # ------------------------------------------------------------------------
    # FOYER / APPROACH GREETING + DENIED BOUNDARY ENFORCEMENT (movement-based)
    # ------------------------------------------------------------------------
    # Notes:
    # - This is independent of WorldGuard and works via cuboid containment checks.
    # - To configure, use /sgfoyer in-game (admin-only).
    # NOTE: Denizen 1.3.x does not have "on player moves".
    # Use "walks" but do NOT rely on context.from/context.to (varies by version).
    on player walks:
      - if !<script[two_person_foyer_config].data_key[enabled].if_null[false]>:
        - stop
      - define world_name <player.world.name>
      # Throttle: movement event can fire very frequently
      - if <player.has_flag[sg_foyer_move_throttle_<[world_name]>]>:
        - stop
      - flag player sg_foyer_move_throttle_<[world_name]> expire:5t
      - if !<server.has_flag[sg_foyer.<[world_name]>.foyer_pos1]>:
        - stop
      - if !<server.has_flag[sg_foyer.<[world_name]>.foyer_pos2]>:
        - stop
      - if !<server.has_flag[sg_foyer.<[world_name]>.denied_pos1]>:
        - stop
      - if !<server.has_flag[sg_foyer.<[world_name]>.denied_pos2]>:
        - stop
      - if !<server.has_flag[sg_foyer.<[world_name]>.return_loc]>:
        - stop
      - run two_person_foyer_walk_check def:<player>|<[world_name]>

    # Also check after teleports/joins (walking event won't fire)
    on player teleports:
      - wait 1t
      - if !<script[two_person_foyer_config].data_key[enabled].if_null[false]>:
        - stop
      - define world_name <player.world.name>
      - if !<server.has_flag[sg_foyer.<[world_name]>.foyer_pos1]>:
        - stop
      - if !<server.has_flag[sg_foyer.<[world_name]>.foyer_pos2]>:
        - stop
      - if !<server.has_flag[sg_foyer.<[world_name]>.denied_pos1]>:
        - stop
      - if !<server.has_flag[sg_foyer.<[world_name]>.denied_pos2]>:
        - stop
      - if !<server.has_flag[sg_foyer.<[world_name]>.return_loc]>:
        - stop
      - run two_person_foyer_walk_check def:<player>|<[world_name]>

    # Optional: right-click NPC near the configured npc_loc to repeat the greeting
    on player right clicks npc:
      - if !<script[two_person_foyer_config].data_key[enabled].if_null[false]>:
        - stop
      - define world_name <player.world.name>
      - if !<server.has_flag[sg_foyer.<[world_name]>.npc_loc]>:
        - stop
      - define npc_loc <server.flag[sg_foyer.<[world_name]>.npc_loc]>
      - if <player.location.distance[<[npc_loc]>]> > 4:
        - stop
      - foreach <script[two_person_foyer_config].data_key[greeting].if_null[<list[]>]> as:line:
        - narrate "<[line]>" targets:<player>

# ============================================================================
# TASK: Background Monitor (runs continuously in a loop)
# ============================================================================
safeguard_background_monitor:
  type: task
  script:
    - announce "<&a>[SAFEGUARD] Starting background monitor (checks every 30 seconds)" to_console
    - while true:
      - run two_person_world_monitor
      - wait 30s

# ============================================================================
# TASK: Foyer Move Check (greeting + denied boundary enforcement)
# ============================================================================
two_person_foyer_walk_check:
  type: task
  definitions: player|world_name
  script:
    - define to_loc <[player].location>
    - define from_loc <[player].flag[sg_foyer_last_loc_<[world_name]>].if_null[<[to_loc]>]>
    - flag <[player]> sg_foyer_last_loc_<[world_name]>:<[to_loc]>
    - define foyer_pos1 <server.flag[sg_foyer.<[world_name]>.foyer_pos1]>
    - define foyer_pos2 <server.flag[sg_foyer.<[world_name]>.foyer_pos2]>
    - define denied_pos1 <server.flag[sg_foyer.<[world_name]>.denied_pos1]>
    - define denied_pos2 <server.flag[sg_foyer.<[world_name]>.denied_pos2]>
    - define return_loc <server.flag[sg_foyer.<[world_name]>.return_loc]>
    - define foyer_cuboid <cuboid[<[foyer_pos1]>|<[foyer_pos2]>]>
    - define denied_cuboid <cuboid[<[denied_pos1]>|<[denied_pos2]>]>

    # Anti-loop: if we just bounced them, don't immediately re-process.
    - if <[player].has_flag[sg_foyer_bounce_cooldown_<[world_name]>]>:
      - stop

    # Optional: sign warning when approaching the boundary (acts like an in-game sign prompt)
    - if <server.has_flag[sg_foyer.<[world_name]>.sign_loc]>:
      - define sign_loc <server.flag[sg_foyer.<[world_name]>.sign_loc]>
      - if <[to_loc].distance[<[sign_loc]>]> <= 6 && !<[player].has_flag[sg_foyer_sign_warned_<[world_name]>]>:
        - narrate "<&e>Notice: <&7>Restricted area ahead." targets:<[player]>
        - narrate "<&7>Children may only proceed with <&b><script[two_person_config].data_key[min_adults]><&7> supervisors (director/observer)." targets:<[player]>
        - flag <[player]> sg_foyer_sign_warned_<[world_name]> expire:30s

    # Greeting when entering foyer cuboid
    - if <[foyer_cuboid].contains_location[<[to_loc]>]> && !<[foyer_cuboid].contains_location[<[from_loc]>]>:
      - define greet_cd <script[two_person_foyer_config].data_key[greet_cooldown].if_null[2m]>
      - if !<[player].has_flag[sg_foyer_greeted_<[world_name]>]>:
        - foreach <script[two_person_foyer_config].data_key[greeting].if_null[<list[]>]> as:line:
          - narrate "<[line]>" targets:<[player]>
        - flag <[player]> sg_foyer_greeted_<[world_name]> expire:<[greet_cd]>

    # Denied boundary enforcement (only when crossing INTO denied cuboid)
    - if <[denied_cuboid].contains_location[<[to_loc]>]> && !<[denied_cuboid].contains_location[<[from_loc]>]>:
      - run two_person_foyer_enforce_denied def:<[player]>|<[world_name]>|<[return_loc]>

    # Safety net: if already inside denied, enforce as well (throttled).
    # This covers cases where the last-loc flag hasn't been set yet or a player logs in/teleports inside.
    - if <[denied_cuboid].contains_location[<[to_loc]>]>:
      - if <[player].has_flag[sg_foyer_denied_enforce_throttle_<[world_name]>]>:
        - stop
      - flag <[player]> sg_foyer_denied_enforce_throttle_<[world_name]> expire:20t
      - run two_person_foyer_enforce_denied def:<[player]>|<[world_name]>|<[return_loc]>

# ============================================================================
# TASK: Continuous World Monitor (runs every 10 seconds)
# ============================================================================
two_person_world_monitor:
  type: task
  script:
    # Get configuration
    - define protected_worlds <script[two_person_config].data_key[protected_worlds]>
    - define supervisor_groups <script[two_person_config].data_key[supervisor_groups]>
    - define child_groups <script[two_person_config].data_key[child_groups]>
    - define min_adults <script[two_person_config].data_key[min_adults]>
    - define exempt_worlds <script[two_person_config].data_key[exempt_worlds]>
    - define vetted_only_worlds <script[two_person_config].data_key[vetted_only_worlds]>
    - define vetted_allowed_groups <script[two_person_config].data_key[vetted_allowed_groups]>
    
    # Check each protected world
    - foreach <[protected_worlds]> as:world_name:
      # Find world by iterating through server.worlds and matching name
      - define world null
      - foreach <server.worlds> as:w:
        - if <[w].name> == <[world_name]>:
          - define world <[w]>
          - announce "<&7>[DEBUG] Found world: <[world_name]>" to_console
          - foreach stop
      - if <[world]> == null:
        - announce "<&7>[DEBUG] World <[world_name]> not found, skipping" to_console
        - foreach next
      
      # Count supervisors and children in this world
      - define supervisor_count 0
      - define children_list <list[]>
      - define nonvetted_list <list[]>
      
      # Skip if no players in world
      - if <[world].players.size> == 0:
        - foreach next
      
      - announce "<&7>[DEBUG] Checking players in world <[world_name]> (<[world].players.size> player(s))" to_console
      
      # Connect to database to get player groups (Vault not available)
      - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
      - wait 1t
      
      - foreach <[world].players> as:p:
        # Get player's permission_level from database
        - define player_name <[p].name>
        - define perm_query "SELECT permission_level FROM known_players WHERE player_name='<[player_name]>' LIMIT 1"
        - ~sql id:db_<queue.id> "query:<[perm_query]>" save:perm_result
        - define perm_rows <entry[perm_result].result_map>
        - define p_group guest
        - if <[perm_rows].size> > 0:
          - define p_group <[perm_rows].get[1].get[permission_level].if_null[guest]>
        
        - if <[supervisor_groups].contains[<[p_group]>]>:
          - define supervisor_count <[supervisor_count].add[1]>
        - if <[child_groups].contains[<[p_group]>]>:
          - define children_list <[children_list].include[<[p]>]>
        # Vetted-only enforcement: kick out anyone not in allowed groups
        - if <[vetted_only_worlds].contains[<[world_name]>]>:
          - if !<[vetted_allowed_groups].contains[<[p_group]>]>:
            - define nonvetted_list <[nonvetted_list].include[<[p]>]>
      
      - sql disconnect id:db_<queue.id>

      # If this is a vetted-only world and any non-vetted players are present, eject them immediately
      - if <[vetted_only_worlds].contains[<[world_name]>]>:
        - if <[nonvetted_list].size> > 0:
          - define lobby_world_name <[exempt_worlds].get[1].if_null[world]>
          - define lobby_world <server.worlds.first>
          - foreach <server.worlds> as:w:
            - if <[w].name> == <[lobby_world_name]>:
              - define lobby_world <[w]>
              - foreach stop
          - define spawn_loc <[lobby_world].spawn_location>
          - foreach <[nonvetted_list]> as:nv:
            - narrate "<&c>⚠ Access Restricted"
            - narrate "<&7>This spiritual direction world is restricted to vetted roles (director/observer) and supervised children." targets:<[nv]>
            - teleport <[nv]> <[spawn_loc]>
          - announce "<&c>[SAFEGUARD] Ejected <&b><[nonvetted_list].size><&c> non-vetted player(s) from vetted world <&e><[world_name]><&c>." to_ops
          - run two_person_log_event def:vetted_world_access_denied|nonvetted_present|entire_world|<[world_name]>|count:<[nonvetted_list].size>
      
      # If children present but insufficient supervision, eject them
      - if <[children_list].size> > 0:
        - if <[supervisor_count]> < <[min_adults]>:
          # VIOLATION: Children in world without adequate supervision
          - announce "<&c>[SAFEGUARD] World <&e><[world_name]><&c> has <&b><[children_list].size> child(ren)<&c> but only <&b><[supervisor_count]>/<[min_adults]> supervisor(s)<&c>. Ejecting children..." to_console
          
          # Find lobby world to send children to
          - define lobby_world_name <[exempt_worlds].get[1].if_null[world]>
          - define lobby_world <server.worlds.first>
          - foreach <server.worlds> as:w:
            - if <[w].name> == <[lobby_world_name]>:
              - define lobby_world <[w]>
              - foreach stop
          - define spawn_loc <[lobby_world].spawn_location>
          
          # Eject each child
          - foreach <[children_list]> as:child:
            - narrate "<&c>⚠ SAFEGUARDING: Insufficient supervision in this world. Returning you to lobby." targets:<[child]>
            - teleport <[child]> <[spawn_loc]>
          
          # Notify admins
          - announce "<&c>[SAFEGUARD] Ejected <&b><[children_list].size> child(ren)<&c> from world <&e><[world_name]><&c> (only <[supervisor_count]>/<[min_adults]> supervisors)" to_ops
          
          # Log event
          - run two_person_log_event def:world_supervision_check_failed|multiple_children|entire_world|<[world_name]>|supervisors:<[supervisor_count]>,children_ejected:<[children_list].size>

# ============================================================================
# TASK: Enforce Denied Boundary (bounce child back if supervision insufficient)
# ============================================================================
two_person_foyer_enforce_denied:
  type: task
  definitions: player|world_name|return_loc
  script:
    # Determine player's group from database (consistent with other safeguards).
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 1t
    - define player_name <[player].name>
    - define perm_query "SELECT permission_level FROM known_players WHERE player_name='<[player_name]>' LIMIT 1"
    - ~sql id:db_<queue.id> "query:<[perm_query]>" save:perm_result
    - define perm_rows <entry[perm_result].result_map>
    - define player_group guest
    - if <[perm_rows].size> > 0:
      - define player_group <[perm_rows].get[1].get[permission_level].if_null[guest]>
    - sql disconnect id:db_<queue.id>

    # Only enforce for children
    - define child_groups <script[two_person_config].data_key[child_groups]>
    - if !<[child_groups].contains[<[player_group]>]>:
      - stop

    # Count supervisors present in this world (DB-backed like other checks)
    - define supervisor_groups <script[two_person_config].data_key[supervisor_groups]>
    - define min_adults <script[two_person_config].data_key[min_adults]>
    - define supervisor_count 0

    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 1t
    - foreach <[player].world.players> as:p:
      - define p_name <[p].name>
      - define p_query "SELECT permission_level FROM known_players WHERE player_name='<[p_name]>' LIMIT 1"
      - ~sql id:db_<queue.id> "query:<[p_query]>" save:p_result
      - define p_rows <entry[p_result].result_map>
      - if <[p_rows].size> > 0:
        - define p_group <[p_rows].get[1].get[permission_level].if_null[guest]>
        - if <[supervisor_groups].contains[<[p_group]>]>:
          - define supervisor_count <[supervisor_count].add[1]>
    - sql disconnect id:db_<queue.id>

    - if <[supervisor_count]> < <[min_adults]>:
      - narrate "<&c>⚠ SAFEGUARDING: Access Denied" targets:<[player]>
      - narrate "<&7>This area requires <&b><[min_adults]> supervising adults<&7> (director/observer) when children are present." targets:<[player]>
      - narrate "<&7>Currently present in world: <&b><[supervisor_count]> supervisor(s)<&7>." targets:<[player]>
      - narrate "<&7>Please wait in the foyer." targets:<[player]>
      - flag <[player]> sg_foyer_bounce_cooldown_<[world_name]> expire:2s
      - teleport <[player]> <[return_loc]>
      - run two_person_log_event def:foyer_denied_boundary_blocked|<[player].name>|denied_boundary|<[world_name]>|supervisors:<[supervisor_count]>

# ============================================================================
# COMMAND: /sgfoyer ...
# Configure foyer/denied boundary locations per-world (admin-only).
# ============================================================================
sgfoyer_command:
  type: command
  name: sgfoyer
  aliases:
    - safeguardfoyer
  description: Configure the safeguarding foyer/denied boundary for the current world
  usage: /sgfoyer show | /sgfoyer test | /sgfoyer run | /sgfoyer set (foyer|denied) (pos1|pos2) | /sgfoyer set return|npc|sign | /sgfoyer clear (foyer|denied|return|npc|sign|all)
  permission: minecraftchurch.admin
  script:
    - define world_name <player.world.name>
    - if <context.args.size> < 1:
      - narrate "<&c>Usage: /sgfoyer show | /sgfoyer test | /sgfoyer run | /sgfoyer set (foyer|denied) (pos1|pos2) | /sgfoyer set return|npc|sign | /sgfoyer clear (foyer|denied|return|npc|sign|all)"
      - determine cancelled

    - define sub <context.args.get[1].to_lowercase>
    - if <[sub]> == show:
      - narrate "<&e>━━━ Safeguard Foyer Config: <&b><[world_name]><&e> ━━━"
      - narrate "<&7>foyer_pos1: <&b><server.flag[sg_foyer.<[world_name]>.foyer_pos1].if_null[<none>]>"
      - narrate "<&7>foyer_pos2: <&b><server.flag[sg_foyer.<[world_name]>.foyer_pos2].if_null[<none>]>"
      - narrate "<&7>denied_pos1: <&b><server.flag[sg_foyer.<[world_name]>.denied_pos1].if_null[<none>]>"
      - narrate "<&7>denied_pos2: <&b><server.flag[sg_foyer.<[world_name]>.denied_pos2].if_null[<none>]>"
      - narrate "<&7>return_loc: <&b><server.flag[sg_foyer.<[world_name]>.return_loc].if_null[<none>]>"
      - narrate "<&7>npc_loc: <&b><server.flag[sg_foyer.<[world_name]>.npc_loc].if_null[<none>]>"
      - narrate "<&7>sign_loc: <&b><server.flag[sg_foyer.<[world_name]>.sign_loc].if_null[<none>]>"
      - determine cancelled

    - if <[sub]> == test:
      - define foyer_pos1 <server.flag[sg_foyer.<[world_name]>.foyer_pos1].if_null[null]>
      - define foyer_pos2 <server.flag[sg_foyer.<[world_name]>.foyer_pos2].if_null[null]>
      - define denied_pos1 <server.flag[sg_foyer.<[world_name]>.denied_pos1].if_null[null]>
      - define denied_pos2 <server.flag[sg_foyer.<[world_name]>.denied_pos2].if_null[null]>
      - if <[foyer_pos1]> == null || <[foyer_pos2]> == null || <[denied_pos1]> == null || <[denied_pos2]> == null:
        - narrate "<&c>Foyer/Denied cuboids not fully set. Use /sgfoyer show"
        - determine cancelled
      - define foyer_cuboid <cuboid[<[foyer_pos1]>|<[foyer_pos2]>]>
      - define denied_cuboid <cuboid[<[denied_pos1]>|<[denied_pos2]>]>
      - define in_foyer <[foyer_cuboid].contains_location[<player.location>]>
      - define in_denied <[denied_cuboid].contains_location[<player.location>]>
      - define min_adults <script[two_person_config].data_key[min_adults]>
      - define child_groups <script[two_person_config].data_key[child_groups]>

      # Pull your group from DB (matches enforcement logic)
      - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
      - wait 1t
      - define player_name <player.name>
      - define perm_query "SELECT permission_level FROM known_players WHERE player_name='<[player_name]>' LIMIT 1"
      - ~sql id:db_<queue.id> "query:<[perm_query]>" save:perm_result
      - define perm_rows <entry[perm_result].result_map>
      - define player_group guest
      - if <[perm_rows].size> > 0:
        - define player_group <[perm_rows].get[1].get[permission_level].if_null[guest]>
      - sql disconnect id:db_<queue.id>
      - define is_child <[child_groups].contains[<[player_group]>]>
      - define would_block <element[<[is_child]>].and[<[in_denied]>]>

      - narrate "<&e>━━━ sgfoyer test: <&b><[world_name]><&e> ━━━"
      - narrate "<&7>Player loc: <&b><player.location>"
      - narrate "<&7>Your group (DB): <&b><[player_group]>"
      - narrate "<&7>Inside foyer: <&b><[in_foyer]>"
      - narrate "<&7>Inside denied: <&b><[in_denied]>"
      - narrate "<&7>Would be blocked in denied: <&b><[would_block]>"
      - if <server.has_flag[sg_foyer.<[world_name]>.sign_loc]>:
        - define sign_loc <server.flag[sg_foyer.<[world_name]>.sign_loc]>
        - narrate "<&7>Distance to sign_loc: <&b><player.location.distance[<[sign_loc]>].round_to[0.01]>"
      - else:
        - narrate "<&7>Distance to sign_loc: <&8>(not set)"
      - determine cancelled

    - if <[sub]> == run:
      - run two_person_foyer_walk_check def:<player>|<[world_name]>
      - narrate "<&a>✓ Ran foyer check for your current location."
      - determine cancelled

    # Clear stored locations (server flags) for this world
    - if <[sub]> == clear:
      - if <context.args.size> < 2:
        - narrate "<&c>Usage: /sgfoyer clear (foyer|denied|return|npc|sign|all)"
        - determine cancelled
      - define what <context.args.get[2].to_lowercase>
      - if <[what]> == all:
        - flag server sg_foyer.<[world_name]>.foyer_pos1:!
        - flag server sg_foyer.<[world_name]>.foyer_pos2:!
        - flag server sg_foyer.<[world_name]>.denied_pos1:!
        - flag server sg_foyer.<[world_name]>.denied_pos2:!
        - flag server sg_foyer.<[world_name]>.return_loc:!
        - flag server sg_foyer.<[world_name]>.npc_loc:!
        - flag server sg_foyer.<[world_name]>.sign_loc:!
        - narrate "<&a>✓ Cleared ALL foyer settings for <&b><[world_name]>"
        - determine cancelled
      - if <[what]> == foyer:
        - flag server sg_foyer.<[world_name]>.foyer_pos1:!
        - flag server sg_foyer.<[world_name]>.foyer_pos2:!
        - narrate "<&a>✓ Cleared foyer_pos1/foyer_pos2 for <&b><[world_name]>"
        - determine cancelled
      - if <[what]> == denied:
        - flag server sg_foyer.<[world_name]>.denied_pos1:!
        - flag server sg_foyer.<[world_name]>.denied_pos2:!
        - narrate "<&a>✓ Cleared denied_pos1/denied_pos2 for <&b><[world_name]>"
        - determine cancelled
      - if <[what]> == return:
        - flag server sg_foyer.<[world_name]>.return_loc:!
        - narrate "<&a>✓ Cleared return_loc for <&b><[world_name]>"
        - determine cancelled
      - if <[what]> == npc:
        - flag server sg_foyer.<[world_name]>.npc_loc:!
        - narrate "<&a>✓ Cleared npc_loc for <&b><[world_name]>"
        - determine cancelled
      - if <[what]> == sign:
        - flag server sg_foyer.<[world_name]>.sign_loc:!
        - narrate "<&a>✓ Cleared sign_loc for <&b><[world_name]>"
        - determine cancelled
      - narrate "<&c>Usage: /sgfoyer clear (foyer|denied|return|npc|sign|all)"
      - determine cancelled

    - if <[sub]> != set:
      - narrate "<&c>Unknown subcommand. Try: /sgfoyer show | /sgfoyer set ... | /sgfoyer clear ..."
      - determine cancelled

    - if <context.args.size> < 2:
      - narrate "<&c>Usage: /sgfoyer set (foyer|denied) (pos1|pos2) | /sgfoyer set return | /sgfoyer set npc | /sgfoyer set sign"
      - determine cancelled

    - define what <context.args.get[2].to_lowercase>
    - if <[what]> == return:
      - flag server sg_foyer.<[world_name]>.return_loc:<player.location>
      - narrate "<&a>✓ Set return_loc for <&b><[world_name]><&a> to <&b><player.location>"
      - determine cancelled
    - if <[what]> == npc:
      - flag server sg_foyer.<[world_name]>.npc_loc:<player.location>
      - narrate "<&a>✓ Set npc_loc for <&b><[world_name]><&a> to <&b><player.location>"
      - determine cancelled
    - if <[what]> == sign:
      - flag server sg_foyer.<[world_name]>.sign_loc:<player.location>
      - narrate "<&a>✓ Set sign_loc for <&b><[world_name]><&a> to <&b><player.location>"
      - determine cancelled

    - if <context.args.size> < 3:
      - narrate "<&c>Usage: /sgfoyer set (foyer|denied) (pos1|pos2)"
      - determine cancelled

    - define which <context.args.get[3].to_lowercase>
    - if <[what]> == foyer:
      - if <[which]> == pos1:
        - flag server sg_foyer.<[world_name]>.foyer_pos1:<player.location>
        - narrate "<&a>✓ Set foyer_pos1 for <&b><[world_name]><&a> to <&b><player.location>"
        - determine cancelled
      - else if <[which]> == pos2:
        - flag server sg_foyer.<[world_name]>.foyer_pos2:<player.location>
        - narrate "<&a>✓ Set foyer_pos2 for <&b><[world_name]><&a> to <&b><player.location>"
        - determine cancelled
      - else:
        - narrate "<&c>Usage: /sgfoyer set foyer (pos1|pos2)"
        - determine cancelled
    - else if <[what]> == denied:
      - if <[which]> == pos1:
        - flag server sg_foyer.<[world_name]>.denied_pos1:<player.location>
        - narrate "<&a>✓ Set denied_pos1 for <&b><[world_name]><&a> to <&b><player.location>"
        - determine cancelled
      - else if <[which]> == pos2:
        - flag server sg_foyer.<[world_name]>.denied_pos2:<player.location>
        - narrate "<&a>✓ Set denied_pos2 for <&b><[world_name]><&a> to <&b><player.location>"
        - determine cancelled
      - else:
        - narrate "<&c>Usage: /sgfoyer set denied (pos1|pos2)"
        - determine cancelled
    - else:
      - narrate "<&c>Usage: /sgfoyer set (foyer|denied) (pos1|pos2) | /sgfoyer set return"
      - determine cancelled

# ============================================================================
# TASK: Check World Entry (Called when player joins/changes to protected world)
# ============================================================================
two_person_check_world_entry:
  type: task
  definitions: player
  script:
    - define world_name <[player].world.name>
    
    # DEBUG
    - announce "<&7>[DEBUG] Checking world entry for <[player].name> in world '<[world_name]>'" to_console
    
    # Get configuration
    - define protected_worlds <script[two_person_config].data_key[protected_worlds]>
    - define exempt_worlds <script[two_person_config].data_key[exempt_worlds]>
    
    # DEBUG
    - announce "<&7>[DEBUG] Protected worlds: <[protected_worlds]>" to_console
    - announce "<&7>[DEBUG] Exempt worlds: <[exempt_worlds]>" to_console
    
    # Check if world is exempt (no supervision required)
    - if <[exempt_worlds].contains[<[world_name]>]>:
      - announce "<&7>[DEBUG] World is exempt, allowing entry" to_console
      - stop
    
    # Check if this world requires two-person rule
    - if !<[protected_worlds].contains[<[world_name]>]>:
      - announce "<&7>[DEBUG] World not in protected list, allowing entry" to_console
      - stop
    
    # Get player's group
    - define player_group <[player].groups.first.if_null[guest]>
    
    # DEBUG
    - announce "<&7>[DEBUG] Player group: <[player_group]>" to_console
    
    # Get supervisor and child groups from config
    - define supervisor_groups <script[two_person_config].data_key[supervisor_groups]>
    - define child_groups <script[two_person_config].data_key[child_groups]>
    - define min_adults <script[two_person_config].data_key[min_adults]>
    
    # Check if entering player is a child
    - define is_child <[child_groups].contains[<[player_group]>]>
    
    # Only check if player is a child
    - if !<[is_child]>:
      - stop
    
    # Count supervisors in this world
    - define supervisor_count 0
    - foreach <[player].world.players> as:p:
      - define p_group <[p].groups.first.if_null[guest]>
      - if <[supervisor_groups].contains[<[p_group]>]>:
        - if <[p]> != <[player]>:
          - define supervisor_count <[supervisor_count].add[1]>
    
    # RULE: Child entering protected world requires minimum adults
    - if <[supervisor_count]> < <[min_adults]>:
      # VIOLATION: Not enough adult supervision in world
      - narrate "<&c>⚠ SAFEGUARDING: This world requires two-person supervision." targets:<[player]>
      - narrate "<&7>World <&b><[world_name]><&7> requires at least <&b><[min_adults]> supervising adults<&7> (director/observer) when children are present." targets:<[player]>
      - narrate "<&7>Currently in world: <&b><[supervisor_count]> supervisor(s)<&7>." targets:<[player]>
      
      # Send child back to lobby (Minecraft Church world)
      - define lobby_worlds <[exempt_worlds]>
      - if <[lobby_worlds].size> > 0:
        - define lobby_world_name <[lobby_worlds].get[1]>
        - define lobby_world <server.world[<[lobby_world_name]>].if_null[null]>
        - if <[lobby_world]> != null:
          - define spawn_loc <[lobby_world].spawn_location>
          - teleport <[player]> <[spawn_loc]>
        - else:
          - teleport <[player]> <[player].world.spawn_location>
      - else:
        - teleport <[player]> <[player].world.spawn_location>
      
      # Notify admins
      - announce "<&c>[SAFEGUARD] <&b><[player].name><&c> blocked from world <&e><[world_name]><&c>: insufficient supervision (<[supervisor_count]>/<[min_adults]> adults)" to_ops
      
      # Log the event
      - run two_person_log_event def:world_entry_blocked|<[player].name>|entire_world|<[world_name]>|supervisors:<[supervisor_count]>
      
      - stop
    
    # Entry allowed - log it
    - narrate "<&a>✓ Entering supervised world (<[supervisor_count]> adult supervisors present)" targets:<[player]>
    - run two_person_log_event def:world_entry_allowed|<[player].name>|entire_world|<[world_name]>|supervisors:<[supervisor_count]>

# ============================================================================
# TASK: Check Entry (Called when player tries to enter)
# ============================================================================
two_person_check_entry:
  type: task
  definitions: player|region_id|world_name
  script:
    # Get region
    - define region <[player].world.cuboid_region[<[region_id]>].if_null[null]>
    - if <[region]> == null:
      - stop
    
    # Get player's group
    - define player_group <[player].groups.first.if_null[guest]>
    
    # Get supervisor and child groups from config
    - define supervisor_groups <script[two_person_config].data_key[supervisor_groups]>
    - define child_groups <script[two_person_config].data_key[child_groups]>
    - define min_adults <script[two_person_config].data_key[min_adults]>
    
    # Check if entering player is a child
    - define is_child <[child_groups].contains[<[player_group]>]>
    
    # Get all players currently in region (including the one entering)
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
    
    # RULE: If a child is entering or already present, require minimum adults
    - if <[child_count]> > 0:
      - if <[supervisor_count]> < <[min_adults]>:
        # VIOLATION: Not enough adult supervision
        - narrate "<&c>⚠ SAFEGUARDING: Two adults required for supervision." targets:<[player]>
        - narrate "<&7>This area requires at least <&b><[min_adults]> supervising adults<&7> (director/observer) when children are present." targets:<[player]>
        - narrate "<&7>Currently in region: <&b><[supervisor_count]> supervisor(s)<&7>, <&b><[child_count]> child(ren)<&7>." targets:<[player]>
        
        # Eject the entering player
        - define spawn_loc <[player].world.spawn_location>
        - teleport <[player]> <[spawn_loc]>
        
        # Notify admins
        - announce "<&c>[SAFEGUARD] <&b><[player].name><&c> blocked from <&e><[region_id]><&c>: insufficient supervision (<[supervisor_count]>/<[min_adults]> adults)" to_ops
        
        # Log the event
        - run two_person_log_event def:entry_blocked|<[player].name>|<[region_id]>|<[world_name]>|supervisors:<[supervisor_count]>,children:<[child_count]>
        
        - stop
    
    # Entry allowed - log it
    - if <[is_child]>:
      - narrate "<&a>✓ Entering supervised area (<[supervisor_count]> adult supervisors present)" targets:<[player]>
      - run two_person_log_event def:entry_allowed|<[player].name>|<[region_id]>|<[world_name]>|supervisors:<[supervisor_count]>,children:<[child_count]>

# ============================================================================
# TASK: Check Exit (Called when player leaves region)
# ============================================================================
two_person_check_exit:
  type: task
  definitions: exiting_player|region_id|world_name
  script:
    # Get region - find world by name
    - define world null
    - foreach <server.worlds> as:w:
      - if <[w].name> == <[world_name]>:
        - define world <[w]>
        - foreach stop
    - if <[world]> == null:
      - stop
    
    - define region <[world].cuboid_region[<[region_id]>].if_null[null]>
    - if <[region]> == null:
      - stop
    
    # Get supervisor and child groups from config
    - define supervisor_groups <script[two_person_config].data_key[supervisor_groups]>
    - define child_groups <script[two_person_config].data_key[child_groups]>
    - define min_adults <script[two_person_config].data_key[min_adults]>
    
    # Get exiting player's group
    - define exiting_group <[exiting_player].groups.first.if_null[guest]>
    - define exiting_was_supervisor <[supervisor_groups].contains[<[exiting_group]>]>
    
    # Only check if a supervisor is leaving
    - if !<[exiting_was_supervisor]>:
      - stop
    
    # Get all players still in region (after exit)
    - define players_in_region <[region].players>
    
    # Count remaining supervisors and children
    - define supervisor_count 0
    - define child_count 0
    - define children_list <list[]>
    
    - foreach <[players_in_region]> as:p:
      - define p_group <[p].groups.first.if_null[guest]>
      - if <[supervisor_groups].contains[<[p_group]>]>:
        - define supervisor_count <[supervisor_count].add[1]>
      - if <[child_groups].contains[<[p_group]>]>:
        - define child_count <[child_count].add[1]>
        - define children_list <[children_list].include[<[p]>]>
    
    # RULE: If children remain but supervision drops below minimum, eject children
    - if <[child_count]> > 0:
      - if <[supervisor_count]> < <[min_adults]>:
        # VIOLATION: Supervision dropped below minimum
        - define spawn_loc <[world].spawn_location>
        
        # Eject all children
        - foreach <[children_list]> as:child:
          - narrate "<&c>⚠ SAFEGUARDING: Adult supervisor left. You are being returned to spawn for safety." targets:<[child]>
          - teleport <[child]> <[spawn_loc]>
        
        # Notify admins
        - announce "<&c>[SAFEGUARD] Supervision dropped in <&e><[region_id]><&c>. Ejected <&b><[child_count]> child(ren)<&c> (only <[supervisor_count]>/<[min_adults]> adults remain)" to_ops
        
        # Log the event
        - run two_person_log_event def:supervision_dropped|<[exiting_player].name>|<[region_id]>|<[world_name]>|supervisors:<[supervisor_count]>,children_ejected:<[child_count]>

# ============================================================================
# TASK: Check Quit (Called when player quits in protected region)
# ============================================================================
two_person_check_quit:
  type: task
  definitions: player_name|region_id|world_name
  script:
    # Get region - find world by name
    - define world null
    - foreach <server.worlds> as:w:
      - if <[w].name> == <[world_name]>:
        - define world <[w]>
        - foreach stop
    - if <[world]> == null:
      - stop
    
    - define region <[world].cuboid_region[<[region_id]>].if_null[null]>
    - if <[region]> == null:
      - stop
    
    # Get supervisor and child groups from config
    - define supervisor_groups <script[two_person_config].data_key[supervisor_groups]>
    - define child_groups <script[two_person_config].data_key[child_groups]>
    - define min_adults <script[two_person_config].data_key[min_adults]>
    
    # Get all players still in region (after quit)
    - define players_in_region <[region].players>
    
    # Count remaining supervisors and children
    - define supervisor_count 0
    - define child_count 0
    - define children_list <list[]>
    
    - foreach <[players_in_region]> as:p:
      - define p_group <[p].groups.first.if_null[guest]>
      - if <[supervisor_groups].contains[<[p_group]>]>:
        - define supervisor_count <[supervisor_count].add[1]>
      - if <[child_groups].contains[<[p_group]>]>:
        - define child_count <[child_count].add[1]>
        - define children_list <[children_list].include[<[p]>]>
    
    # RULE: If children remain but supervision drops below minimum, eject children
    - if <[child_count]> > 0:
      - if <[supervisor_count]> < <[min_adults]>:
        # VIOLATION: Player quit caused supervision to drop
        - define spawn_loc <[world].spawn_location>
        
        # Eject all children
        - foreach <[children_list]> as:child:
          - narrate "<&c>⚠ SAFEGUARDING: Adult supervisor disconnected. You are being returned to spawn for safety." targets:<[child]>
          - teleport <[child]> <[spawn_loc]>
        
        # Notify admins
        - announce "<&c>[SAFEGUARD] <&b><[player_name]><&c> quit from <&e><[region_id]><&c>. Ejected <&b><[child_count]> child(ren)<&c> (only <[supervisor_count]>/<[min_adults]> adults remain)" to_ops
        
        # Log the event
        - run two_person_log_event def:supervisor_quit|<[player_name]>|<[region_id]>|<[world_name]>|supervisors:<[supervisor_count]>,children_ejected:<[child_count]>

# ============================================================================
# TASK: Log Safeguarding Events to Database
# ============================================================================
two_person_log_event:
  type: task
  definitions: event_type|player_name|region_id|world_name|details
  script:
    # Check if audit logging is enabled
    - define audit_enabled <script[two_person_config].data_key[audit_logging]>
    - if !<[audit_enabled]>:
      - stop
    
    # Connect to database
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s
    
    # Escape values for SQL
    - define player_escaped <[player_name].replace[']][\\']>
    # For JSON, escape backslashes and double-quotes, plus SQL single-quote.
    - define region_json <[region_id].replace[\\][\\\\].replace["][\\\"].replace[']][\\']>
    - define world_json <[world_name].replace[\\][\\\\].replace["][\\\"].replace[']][\\']>
    - define details_json <[details].replace[\\][\\\\].replace["][\\\"].replace[']][\\']>
    
    # Insert audit log entry
    # Store valid JSON in audit_log.details (JSON column)
    - define details_obj "{\"region\":\"<[region_json]>\",\"world\":\"<[world_json]>\",\"details\":\"<[details_json]>\"}"
    - define log_query "INSERT INTO audit_log (action_type, target_player, details, created_at) VALUES ('safeguard_<[event_type]>', '<[player_escaped]>', '<[details_obj]>', NOW())"
    - ~sql id:db_<queue.id> "update:<[log_query]>"
    
    - sql disconnect id:db_<queue.id>

# ============================================================================
# COMMAND: /safeguard status [region]
# View current supervision status in protected regions
# ============================================================================
safeguard_status_command:
  type: command
  name: safeguard
  aliases:
    - sg
    - supervision
  description: Check two-person safeguarding status
  usage: /safeguard status [region] | /safeguard list
  permission: minecraftchurch.admin
  script:
    - if <context.args.size> < 1:
      - narrate "<&c>Usage: /safeguard status [region] | /safeguard list"
      - determine cancelled
    
    - define subcommand <context.args.get[1]>
    
    # List all protected regions and worlds
    - if <[subcommand]> == list:
      - narrate "<&e>━━━ Protected Areas (Two-Person Rule) ━━━"
      
      # Show protected worlds (entire worlds requiring supervision)
      - define protected_worlds <script[two_person_config].data_key[protected_worlds]>
      - if <[protected_worlds].size> > 0:
        - narrate "<&a>Protected Worlds (entire world requires supervision):"
        - foreach <[protected_worlds]> as:world_name:
          - narrate "<&7>  - <&b><[world_name]><&7> (entire world)"
        - narrate "<&7>Total: <&b><[protected_worlds].size><&7> world(s)"
      
      # Show specific protected regions
      - define protected_regions <script[two_person_config].data_key[regions]>
      - if <[protected_regions].size> > 0:
        - narrate ""
        - narrate "<&a>Protected Regions (specific areas):"
        - foreach <[protected_regions]> as:region_data:
          - narrate "<&7>  - <&b><[region_data]>"
        - narrate "<&7>Total: <&b><[protected_regions].size><&7> region(s)"
      
      # Show exempt worlds
      - define exempt_worlds <script[two_person_config].data_key[exempt_worlds]>
      - if <[exempt_worlds].size> > 0:
        - narrate ""
        - narrate "<&7>Exempt Worlds (no supervision required):"
        - foreach <[exempt_worlds]> as:world_name:
          - narrate "<&7>  - <&8><[world_name]><&7> (public/lobby)"
      
      - determine cancelled
    
    # Check status of specific region
    - if <[subcommand]> == status:
      - if <context.args.size> < 2:
        - narrate "<&c>Usage: /safeguard status <region>"
        - narrate "<&7>Example: /safeguard status room7"
        - determine cancelled
      
      - define region_id <context.args.get[2]>
      - define world <player.world>
      
      # Get region
      - define region <[world].cuboid_region[<[region_id]>].if_null[null]>
      - if <[region]> == null:
        - narrate "<&c>Region '<[region_id]>' not found in this world!"
        - determine cancelled
      
      # Get config
      - define supervisor_groups <script[two_person_config].data_key[supervisor_groups]>
      - define child_groups <script[two_person_config].data_key[child_groups]>
      - define min_adults <script[two_person_config].data_key[min_adults]>
      
      # Get all players in region
      - define players_in_region <[region].players>
      
      # Count and list supervisors and children
      - define supervisor_count 0
      - define child_count 0
      - define supervisors_list <list[]>
      - define children_list <list[]>
      
      - foreach <[players_in_region]> as:p:
        - define p_group <[p].groups.first.if_null[guest]>
        - if <[supervisor_groups].contains[<[p_group]>]>:
          - define supervisor_count <[supervisor_count].add[1]>
          - define supervisors_list <[supervisors_list].include[<[p].name>_(<[p_group]>)]>
        - if <[child_groups].contains[<[p_group]>]>:
          - define child_count <[child_count].add[1]>
          - define children_list <[children_list].include[<[p].name>]>
      
      # Display status
      - narrate "<&e>━━━ Safeguarding Status: <&b><[region_id]><&e> ━━━"
      - narrate "<&7>World: <&b><[world].name>"
      - narrate "<&7>Minimum adults required: <&b><[min_adults]>"
      - narrate ""
      - narrate "<&7>Current supervision:"
      - narrate "<&7>  Supervisors: <&b><[supervisor_count]><&7> (minimum: <[min_adults]>)"
      - if <[supervisors_list].size> > 0:
        - foreach <[supervisors_list]> as:sup:
          - narrate "<&7>    - <&b><[sup]>"
      - else:
        - narrate "<&7>    - <&8>None"
      
      - narrate "<&7>  Children: <&b><[child_count]>"
      - if <[children_list].size> > 0:
        - foreach <[children_list]> as:kid:
          - narrate "<&7>    - <&b><[kid]>"
      - else:
        - narrate "<&7>    - <&8>None"
      
      - narrate ""
      # Check compliance
      - if <[child_count]> > 0:
        - if <[supervisor_count]> >= <[min_adults]>:
          - narrate "<&a>✓ COMPLIANT: Adequate supervision"
        - else:
          - narrate "<&c>⚠ VIOLATION: Insufficient supervision!"
          - narrate "<&c>  Required: <[min_adults]> supervisors | Present: <[supervisor_count]>"
      - else:
        - narrate "<&7>✓ No children present (supervision not required)"
      
      - determine cancelled
    
    # Unknown subcommand
    - narrate "<&c>Unknown subcommand: <[subcommand]>"
    - narrate "<&7>Available: status, list"
    - determine cancelled
