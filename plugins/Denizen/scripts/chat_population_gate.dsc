# chat_population_gate.dsc
# Blocks public chat when fewer than 3 players are online.
#
# Bypass permission: minecraftchurch.chat.bypass
# (give this to admins if you want staff to talk while population is low)

chat_population_gate:
  type: world
  debug: false
  events:
    on player chats:
      - define online <server.online_players.size>
      - if <[online]> < 3:
        - if <player.has_permission[minecraftchurch.chat.bypass]||false>:
          - stop
        - determine cancelled
        - narrate "<&c>Chat is disabled until at least <&b>3<&c> players are online."

