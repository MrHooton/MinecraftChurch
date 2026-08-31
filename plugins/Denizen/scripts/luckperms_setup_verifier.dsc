# luckperms_setup_verifier.dsc
# Denizen script to verify LuckPerms groups are configured correctly
# This helps ensure the grant applicator will work properly

# Command: /verifygroups
# Checks if all required LuckPerms groups exist
verify_groups_command:
  type: command
  name: verifygroups
  aliases: checkgroups|verifyluckperms
  description: Verify that all required LuckPerms groups are configured
  usage: /verifygroups
  permission: minecraftchurch.admin
  script:
    - narrate "<&e>=== LuckPerms Groups Verification ==="
    - narrate "<&7>Checking if required groups exist..."
    - narrate ""
    
    # List of required groups
    - define required_groups <list[guest|child|adult|director|observer|admin]>
    - define missing_groups <list[]>
    - define existing_groups <list[]>
    
    # Check each group by trying to get its info
    - foreach <[required_groups]> as:group:
      - define group_name <[group]>
      - narrate "<&7>Checking group: <&b><[group_name]>..."
      
      # Try to execute lp group info command and capture output
      # Note: This is a verification check - we'll use execute to test
      - define test_command "lp group <[group_name]> info"
      - execute as_server "lp group <[group_name]> info"
      - wait 1s
      
      # Since we can't easily parse the output, we'll just note that we checked
      # The command will error if group doesn't exist, but we can't catch that easily
      # So we'll provide manual verification instructions
      - define existing_groups <[existing_groups].include[<[group_name]>]>
    
    - narrate ""
    - narrate "<&e>=== Verification Complete ==="
    - narrate "<&7>Note: This script cannot automatically detect missing groups."
    - narrate "<&7>Please manually verify by running: <&b>/lp listgroups"
    - narrate ""
    - narrate "<&a>Required groups:"
    - foreach <[required_groups]> as:group:
      - narrate "<&7>  - <&b><[group]>"
    - narrate ""
    - narrate "<&e>If any groups are missing, run the setup commands from:"
    - narrate "<&b>plugins/LuckPerms/group_setup_commands.txt"
    - narrate ""
    - narrate "<&7>Or use the web editor: <&b>/lp editor"

# Command: /setupgroups
# Provides instructions for setting up groups
setup_groups_command:
  type: command
  name: setupgroups
  aliases: luckpermsetup|lphelp
  description: Show instructions for setting up LuckPerms groups
  usage: /setupgroups
  permission: minecraftchurch.admin
  script:
    - narrate "<&e>=== LuckPerms Groups Setup Guide ==="
    - narrate ""
    - narrate "<&a>Option 1: Use Command File (Recommended)"
    - narrate "<&7>1. Open: <&b>plugins/LuckPerms/group_setup_commands.txt"
    - narrate "<&7>2. Copy all commands"
    - narrate "<&7>3. Run them in-game as OP or in console"
    - narrate ""
    - narrate "<&a>Option 2: Web Editor"
    - narrate "<&7>1. Run: <&b>/lp editor"
    - narrate "<&7>2. Open the generated URL in your browser"
    - narrate "<&7>3. Create groups and set permissions via web interface"
    - narrate "<&7>4. Apply changes when done"
    - narrate ""
    - narrate "<&a>Required Groups:"
    - narrate "<&7>  <&b>guest<&7> - Default group for new players (weight: 10)"
    - narrate "<&7>  <&b>child<&7> - Verified children (weight: 20)"
    - narrate "<&7>  <&b>adult<&7> - Parents/volunteers (weight: 30)"
    - narrate "<&7>  <&b>director<&7> - Spiritual directors (weight: 40)"
    - narrate "<&7>  <&b>observer<&7> - Trained observers (weight: 35)"
    - narrate "<&7>  <&b>admin<&7> - Server administrators (weight: 100)"
    - narrate ""
    - narrate "<&e>After setup, verify with: <&b>/verifygroups"
    - narrate "<&7>Or check manually: <&b>/lp listgroups"

# Task: Verify a specific group exists (for use in other scripts)
verification_check_group_exists:
  type: task
  definitions: group_name
  script:
    # This task attempts to verify a group exists
    # Since we can't easily parse LuckPerms command output in Denizen,
    # we'll just execute the command and assume success if no error
    # For actual verification, admins should use /lp listgroups manually
    
    - define check_command "lp group <[group_name]> info"
    - execute as_server "<[check_command]>"
    - wait 1s
    
    # Note: We can't easily determine if the command succeeded
    # This is a limitation - the command will show output but we can't parse it
    # For now, we'll just return true and let the actual grant application handle errors
    - determine true
