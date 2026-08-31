# sd_observer_tools.dsc
# Tools for vetted SD staff (director/observer) that avoid private DMs.
# - /sdalert <message> : notify directors/admins (logged to console)
# - /sdend : end the SD session (teleport everyone in sd to lobby)

sd_staff_tools:
  type: world
  debug: false
  events:
    # Prevent observers from chatting in vetted SD worlds (they should use /sdalert)
    on player chats:
      - define vetted_worlds <script[two_person_config].data_key[vetted_only_worlds]||li@sd>
      - if !<[vetted_worlds].contains[<player.world.name>]>:
        - stop
      # Look up group from DB (same source of truth used by safeguard)
      - ~sql id:db_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
      - wait 1t
      - define q "SELECT permission_level FROM known_players WHERE player_name='<player.name>' LIMIT 1"
      - ~sql id:db_<queue.id> "query:<[q]>" save:pr
      - define rows <entry[pr].result_map>
      - sql disconnect id:db_<queue.id>
      - define grp guest
      - if <[rows].size> > 0:
        - define grp <[rows].get[1].get[permission_level].if_null[guest]>
      - if <[grp]> == observer:
        - determine cancelled
        - narrate "<&7>Observers cannot use public chat in SD. Use <&b>/sdalert <message><&7>."

sdalert_command:
  type: command
  name: sdalert
  description: Alert directors/admins about a safeguarding concern (logged to console)
  usage: /sdalert [message]
  permission: minecraftchurch.sd.alert
  script:
    - if <context.source_type> != player:
      - narrate "<&c>Run this command in-game."
      - determine cancelled
    - if <context.args.size> < 1:
      - narrate "<&c>Usage: /sdalert [message]"
      - determine cancelled
    - define msg <context.args.to[<context.args.size>].join[ ]>
    - announce "<&c>[SD ALERT] <player.name>: <[msg]>" to_console
    - announce "<&c>[SD ALERT] <player.name>: <[msg]>" to_ops
    - foreach <server.online_players> as:p:
      - if <[p].has_permission[minecraftchurch.sd.alerts]||false>:
        - narrate "<&c>[SD ALERT] <player.name>: <&f><[msg]>" targets:<[p]>
    - narrate "<&a>Alert sent."

sdend_command:
  type: command
  name: sdend
  description: End the SD session and return everyone in SD to the lobby
  usage: /sdend
  permission: minecraftchurch.sd.end
  script:
    - if <context.source_type> != player:
      - narrate "<&c>Run this command in-game."
      - determine cancelled

    - define vetted_worlds <script[two_person_config].data_key[vetted_only_worlds]||li@sd>
    - define here <player.world.name>
    - if !<[vetted_worlds].contains[<[here]>]>:
      - narrate "<&c>This command can only be used from within an SD world."
      - determine cancelled

    - define exempt_worlds <script[two_person_config].data_key[exempt_worlds]||li@Minecraft_Church>
    - define lobby_world_name <[exempt_worlds].get[1].if_null[world]>
    - define lobby_world <server.worlds.first>
    - foreach <server.worlds> as:w:
      - if <[w].name> == <[lobby_world_name]>:
        - define lobby_world <[w]>
        - foreach stop
    - define spawn_loc <[lobby_world].spawn_location>

    - announce "<&c>[SD END] Session ended by <player.name>. Returning all players to lobby." to_console
    - foreach <player.world.players> as:p:
      - narrate "<&c>Session ended. Returning you to lobby." targets:<[p]>
      - teleport <[p]> <[spawn_loc]>
