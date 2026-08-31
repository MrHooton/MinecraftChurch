# worldguard_region_helper.dsc
# Denizen script to help verify and configure WorldGuard regions
# Provides commands to check region status and provide setup guidance

# Command: /verifyregions
# Checks if required WorldGuard regions are configured correctly
verify_regions_command:
  type: command
  name: verifyregions
  aliases: checkregions|verifywg
  description: Verify that required WorldGuard regions are configured
  usage: /verifyregions
  permission: minecraftchurch.admin
  script:
    - narrate "<&e>=== WorldGuard Regions Verification ==="
    - narrate "<&7>Checking required regions..."
    - narrate ""
    
    # Check if player is in the correct world
    - if <player.world.name> != "Minecraft_Church":
      - narrate "<&c>Warning: You are not in Minecraft_Church world!"
      - narrate "<&7>Some regions may not be visible. Please run this command in Minecraft_Church world."
      - narrate ""
    
    - narrate "<&a>Required Regions:"
    - narrate "<&7>  <&b>__global__<&7> - Base protection for entire world"
    - narrate "<&7>  <&b>room7<&7> - Restricted room with membership access"
    - narrate "<&7>  <&b>doorkeep<&7> - NPC location (optional)"
    - narrate ""
    - narrate "<&e>To check region details, use:"
    - narrate "<&b>/rg info <region_name>"
    - narrate ""
    - narrate "<&e>To list all regions:"
    - narrate "<&b>/rg list"
    - narrate ""
    - narrate "<&7>Note: This script provides guidance. Use WorldGuard commands to verify."

# Command: /regionhelp
# Provides help and instructions for WorldGuard region setup
region_help_command:
  type: command
  name: regionhelp
  aliases: wghelp|regionguide
  description: Show WorldGuard region setup instructions
  usage: /regionhelp
  permission: minecraftchurch.admin
  script:
    - narrate "<&e>=== WorldGuard Region Setup Guide ==="
    - narrate ""
    - narrate "<&a>1. Verify __global__ Region"
    - narrate "<&7>Run these commands to ensure base protection:"
    - narrate "<&b>/rg flag __global__ build deny"
    - narrate "<&b>/rg flag __global__ block-break deny"
    - narrate "<&b>/rg flag __global__ block-place deny"
    - narrate "<&b>/rg flag __global__ use deny"
    - narrate "<&b>/rg flag __global__ entry allow"
    - narrate "<&b>/rg flag __global__ exit allow"
    - narrate ""
    - narrate "<&a>2. Verify room7 Region"
    - narrate "<&7>Check membership and flags:"
    - narrate "<&b>/rg info room7"
    - narrate "<&7>Should show groups: child, director, observer"
    - narrate "<&7>If use flag is missing, add it:"
    - narrate "<&b>/rg flag room7 use allow"
    - narrate ""
    - narrate "<&a>3. Create Foyer Region (Optional)"
    - narrate "<&7>Use WorldGuard wand to select area:"
    - narrate "<&b>/rg wand"
    - narrate "<&7>Left-click first corner, right-click second corner"
    - narrate "<&b>/rg define foyer"
    - narrate "<&b>/rg flag foyer entry allow"
    - narrate "<&b>/rg flag foyer use deny"
    - narrate "<&b>/rg flag foyer interact allow"
    - narrate ""
    - narrate "<&a>4. Test Access"
    - narrate "<&7>Test as guest (should fail):"
    - narrate "<&b>/lp user TestPlayer parent set guest"
    - narrate "<&7>Test as child (should succeed):"
    - narrate "<&b>/lp user TestPlayer parent set child"
    - narrate ""
    - narrate "<&e>For full documentation, see:"
    - narrate "<&b>plugins/WorldGuard/WORLDGUARD_SETUP_GUIDE.md"

# Command: /checkroom7
# Quick check for room7 region configuration
check_room7_command:
  type: command
  name: checkroom7
  aliases: room7check|checkroom
  description: Check room7 region configuration
  usage: /checkroom7
  permission: minecraftchurch.admin
  script:
    - narrate "<&e>=== room7 Region Check ==="
    - narrate ""
    - narrate "<&7>Expected Configuration:"
    - narrate "<&a>  Location: {x: 1, y: 63, z: 115} to {x: 3, y: 65, z: 123}"
    - narrate "<&a>  Members: g:child, g:director, g:observer"
    - narrate "<&a>  Flags: entry deny, use allow"
    - narrate "<&a>  Priority: 20"
    - narrate ""
    - narrate "<&7>To verify, run:"
    - narrate "<&b>/rg info room7"
    - narrate ""
    - narrate "<&7>If membership is missing, add groups:"
    - narrate "<&b>/rg addmember room7 g:child"
    - narrate "<&b>/rg addmember room7 g:director"
    - narrate "<&b>/rg addmember room7 g:observer"
    - narrate ""
    - narrate "<&7>If use flag is missing:"
    - narrate "<&b>/rg flag room7 use allow"

# Command: /setupfoyer [region_name]
# Provides step-by-step instructions to create a foyer region
setup_foyer_command:
  type: command
  name: setupfoyer
  aliases: createfoyer|foyersetup
  description: Get instructions to create a foyer region
  usage: /setupfoyer [region_name]
  permission: minecraftchurch.admin
  script:
    - define region_name "foyer"
    - if <context.args.size> > 0:
      - define region_name <context.args.get[1]>
    
    - narrate "<&e>=== Foyer Region Setup Guide ==="
    - narrate ""
    - narrate "<&7>Foyer regions provide welcoming areas before restricted rooms."
    - narrate "<&7>They allow signs and NPCs while preventing building/breaking."
    - narrate ""
    - narrate "<&a>Step 1: Get WorldGuard Wand"
    - narrate "<&b>/rg wand"
    - narrate ""
    - narrate "<&a>Step 2: Select Area"
    - narrate "<&7>Stand at the entrance area where you want the foyer."
    - narrate "<&7>Left-click: First corner"
    - narrate "<&7>Right-click: Second corner"
    - narrate ""
    - narrate "<&a>Step 3: Create Region"
    - narrate "<&b>/rg define <[region_name]>"
    - narrate ""
    - narrate "<&a>Step 4: Set Flags"
    - narrate "<&b>/rg flag <[region_name]> entry allow"
    - narrate "<&b>/rg flag <[region_name]> use deny"
    - narrate "<&b>/rg flag <[region_name]> interact allow"
    - narrate "<&b>/rg flag <[region_name]> build deny"
    - narrate "<&b>/rg flag <[region_name]> block-break deny"
    - narrate "<&b>/rg flag <[region_name]> block-place deny"
    - narrate ""
    - narrate "<&a>Step 5: Set Priority"
    - narrate "<&b>/rg setpriority <[region_name]> 10"
    - narrate "<&7>(Lower than room7's priority of 20)"
    - narrate ""
    - narrate "<&a>Step 6: Verify"
    - narrate "<&b>/rg info <[region_name]>"
    - narrate ""
    - narrate "<&7>Now you can place signs and NPCs in this area!"
