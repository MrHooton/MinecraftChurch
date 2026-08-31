# File: scripts/permission_admin.dsc
# In-game permission promotion (DB-backed)
# Levels: guest, child, adult, director, observer, admin

set_permission_level_command:
  type: command
  name: setperm
  description: Set a player's DB permission_level (guest/child/adult/director/observer/admin)
  usage: /setperm [player] [level]
  permission: minecraftchurch.superadmin
  script:
    - if <context.source_type> != player:
      - narrate "<&c>Run this command in-game."
      - determine cancelled

    - if <context.args.size> < 2:
      - narrate "<&c>Usage: /setperm [player] [level]"
      - narrate "<&7>Levels: guest, child, adult, director, observer, admin"
      - narrate "<&7>Example: /setperm SternFawn admin"
      - determine cancelled

    - define target <context.args.get[1]>
    - define level <context.args.get[2].to_lowercase>

    # Allow only your defined levels
    - define allowed li@guest|child|adult|director|observer|admin
    - if <[allowed].contains[<[level]>].not>:
      - narrate "<&c>Invalid level: <&f><[level]>"
      - narrate "<&7>Allowed: guest, child, adult, director, observer, admin"
      - determine cancelled

    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s

    # Update database permission_level
    - define q "UPDATE known_players SET permission_level='<[level]>' WHERE player_name='<[target]>' LIMIT 1"
    - ~sql id:db_<queue.id> "update:<[q]>"
    - sql disconnect id:db_<queue.id>

    # Also update LuckPerms group to keep them in sync
    - narrate "<&7>Updating LuckPerms group for <&b><[target]><&7>..."
    
    # Check if player is online (helps with immediate application)
    - define target_player <server.match_player[<[target]>]>
    - define is_online <[target_player].is_player>
    
    # Execute LuckPerms command to set group
    # Try both methods to ensure it works
    - narrate "<&7>Executing: <&b>lp user <[target]> parent set <[level]>"
    - execute as_server "lp user <[target]> parent set <[level]>"
    - wait 3s
    
    # Force LuckPerms to sync (important for offline players and storage sync)
    - execute as_server "lp sync"
    - wait 2s
    
    - if <[is_online]>:
      - narrate "<&7>Player is online - changes should apply immediately."
      - narrate "<&7>If group didn't change, player may need to relog."
    - else:
      - narrate "<&7>Player is offline - changes will apply on next login."
    
    - narrate "<&a>✓ Set <&b><[target]><&a> permission_level to <&e><[level]><&a>."
    - narrate "<&7>Database updated ✓ | LuckPerms command executed ✓"
    - narrate "<&7>⚠ IMPORTANT: Verify with: <&b>/lp user <[target]> info"
    - narrate "<&7>If group is still wrong, run manually: <&b>/lp user <[target]> parent set <[level]>"

# Command: /checkperm <player>
# Check if database permission_level matches LuckPerms group
check_permission_sync_command:
  type: command
  name: checkperm
  description: Check if database permission_level matches LuckPerms group
  usage: /checkperm [player]
  permission: minecraftchurch.superadmin
  script:
    - if <context.args.size> < 1:
      - narrate "<&c>Usage: /checkperm [player]"
      - narrate "<&7>Example: /checkperm SternFawn"
      - determine cancelled

    - define target <context.args.get[1]>
    
    # Get database permission_level
    - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 2s
    
    - define query "SELECT permission_level FROM known_players WHERE player_name='<[target]>' LIMIT 1"
    - ~sql id:db_<queue.id> "query:<[query]>" save:perm_check
    - define rows <entry[perm_check].result_map>
    - sql disconnect id:db_<queue.id>
    
    - if <[rows].size> == 0:
      - narrate "<&c>Player '<&f><[target]><&c>' not found in database!"
      - determine cancelled
    
    - define db_level <[rows].get[1].get[permission_level]>
    
    # Get LuckPerms group (we'll use a workaround since we can't directly query LuckPerms)
    - narrate "<&e>━━━ Permission Sync Check ━━━"
    - narrate "<&7>Player: <&b><[target]>"
    - narrate "<&7>Database permission_level: <&b><[db_level]>"
    - narrate "<&7>LuckPerms group: <&7>(Run <&b>/lp user <[target]> info<&7> to check)"
    - narrate ""
    - narrate "<&7>To sync if mismatched: <&b>/setperm <[target]> <[db_level]>"
    - narrate "<&e>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Command: /fixchildperms
# Fix child group permissions to ensure private messaging is disabled
fix_child_permissions_command:
  type: command
  name: fixchildperms
  description: Fix child group permissions to disable private messaging
  usage: /fixchildperms
  permission: minecraftchurch.superadmin
  script:
    - narrate "<&7>Fixing child group permissions..."
    
    # Ensure child group has explicit denials for private messaging
    - execute as_server "lp group child permission set minecraft.command.tell false"
    - wait 1s
    - execute as_server "lp group child permission set minecraft.command.msg false"
    - wait 1s
    - execute as_server "lp group child permission set minecraft.command.w false"
    - wait 1s
    
    # Also ensure guest group has these denials (child inherits from guest)
    - execute as_server "lp group guest permission set minecraft.command.tell false"
    - wait 1s
    - execute as_server "lp group guest permission set minecraft.command.msg false"
    - wait 1s
    - execute as_server "lp group guest permission set minecraft.command.w false"
    - wait 1s
    
    - narrate "<&a>✓ Child group permissions fixed!"
    - narrate "<&7>Private messaging should now be disabled for child group."
    - narrate "<&7>Players may need to relog for changes to take effect."

# Command: /lockdms
# Disable private messaging server-wide (recommended: DMs are hard to audit)
lock_dms_command:
  type: command
  name: lockdms
  description: Disable private messaging commands for all groups (tell/msg/w)
  usage: /lockdms
  permission: minecraftchurch.superadmin
  script:
    - narrate "<&7>Disabling private messaging commands for all groups..."

    # Deny for all groups (including staff) to prevent adult->child whispers.
    - foreach li@guest|child|adult|director|observer|admin as:g:
      - execute as_server "lp group <[g]> permission set minecraft.command.tell false"
      - wait 1s
      - execute as_server "lp group <[g]> permission set minecraft.command.msg false"
      - wait 1s
      - execute as_server "lp group <[g]> permission set minecraft.command.w false"
      - wait 1s

    - execute as_server "lp sync"
    - wait 1s
    - narrate "<&a>✓ Private messaging disabled for all groups."
    - narrate "<&7>Players may need to relog."

# Command: /fixsdstaffperms
# Grants SD staff permissions to director/observer groups:
# - allow /sdalert, /sdend
# - allow receiving sd alerts
fix_sd_staff_perms_command:
  type: command
  name: fixsdstaffperms
  description: Grant SD staff permissions to director/observer groups
  usage: /fixsdstaffperms
  permission: minecraftchurch.superadmin
  script:
    - narrate "<&7>Granting SD staff permissions to director/observer..."
    - execute as_server "lp group director permission set minecraftchurch.sd.alert true"
    - wait 1s
    - execute as_server "lp group observer permission set minecraftchurch.sd.alert true"
    - wait 1s
    - execute as_server "lp group director permission set minecraftchurch.sd.end true"
    - wait 1s
    - execute as_server "lp group observer permission set minecraftchurch.sd.end true"
    - wait 1s
    - execute as_server "lp group director permission set minecraftchurch.sd.alerts true"
    - wait 1s
    - execute as_server "lp group observer permission set minecraftchurch.sd.alerts true"
    - wait 1s
    - execute as_server "lp sync"
    - wait 1s
    - narrate "<&a>✓ SD staff permissions granted."

# Command: /fixplayerperms <player>
# Remove any explicit messaging permissions from a player that might override group permissions
fix_player_permissions_command:
  type: command
  name: fixplayerperms
  description: Remove explicit messaging permissions from a player
  usage: /fixplayerperms [player]
  permission: minecraftchurch.superadmin
  script:
    - if <context.args.size> < 1:
      - narrate "<&c>Usage: /fixplayerperms [player]"
      - narrate "<&7>Example: /fixplayerperms sternfawn"
      - determine cancelled

    - define target <context.args.get[1]>
    - narrate "<&7>Removing explicit messaging permissions from <&b><[target]><&7>..."
    
    # Remove any explicit permissions that might allow messaging
    - execute as_server "lp user <[target]> permission unset minecraft.command.tell"
    - wait 1s
    - execute as_server "lp user <[target]> permission unset minecraft.command.msg"
    - wait 1s
    - execute as_server "lp user <[target]> permission unset minecraft.command.w"
    - wait 1s
    
    # Also explicitly deny them to ensure they're blocked
    - execute as_server "lp user <[target]> permission set minecraft.command.tell false"
    - wait 1s
    - execute as_server "lp user <[target]> permission set minecraft.command.msg false"
    - wait 1s
    - execute as_server "lp user <[target]> permission set minecraft.command.w false"
    - wait 1s
    
    - narrate "<&a>✓ Removed explicit messaging permissions from <&b><[target]>"
    - narrate "<&7>Player should now follow group permissions."
    - narrate "<&7>Player may need to relog for changes to take effect."

# Command: /syncperm <player> <level>
# Manually sync a player's LuckPerms group (use if /setperm doesn't work)
sync_permission_manual_command:
  type: command
  name: syncperm
  description: Manually sync LuckPerms group for a player
  usage: /syncperm [player] [level]
  permission: minecraftchurch.superadmin
  script:
    - if <context.args.size> < 2:
      - narrate "<&c>Usage: /syncperm [player] [level]"
      - narrate "<&7>Example: /syncperm SternFawn admin"
      - narrate "<&7>This command ONLY updates LuckPerms (not database)"
      - determine cancelled

    - define target <context.args.get[1]>
    - define level <context.args.get[2].to_lowercase>
    
    # Validate level
    - define allowed li@guest|child|adult|director|observer|admin
    - if <[allowed].contains[<[level]>].not>:
      - narrate "<&c>Invalid level: <&f><[level]>"
      - narrate "<&7>Allowed: guest, child, adult, director, observer, admin"
      - determine cancelled
    
    - narrate "<&7>Manually syncing LuckPerms group..."
    - narrate "<&7>Executing: <&b>lp user <[target]> parent set <[level]>"
    
    # Execute the command
    - execute as_server "lp user <[target]> parent set <[level]>"
    - wait 2s
    
    # Sync LuckPerms
    - execute as_server "lp sync"
    - wait 1s
    
    - narrate "<&a>✓ LuckPerms group updated to <&e><[level]>"
    - narrate "<&7>Verify with: <&b>/lp user <[target]> info"
    - narrate "<&7>⚠ Note: Database was NOT updated. Use /setperm to sync both."
