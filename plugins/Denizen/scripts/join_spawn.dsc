# join_spawn.dsc
# Sends every player to the Minecraft Church hub after login.
# Multiverse's join-destination is disabled; this script is the source of truth.

minecraft_church_join_spawn:
  type: world
  debug: false
  events:
    on player joins:
      - wait 10t
      - teleport <player> l@14,63,93,13,97,Minecraft_Church
