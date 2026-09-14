# identity_hardening.dsc
# UUID-first player registration and identity diagnostics.
# This intentionally does NOT change Floodgate prefix or server online-mode.
# It is designed to make the existing no-prefix configuration safer before migration.

# Register/update a player using UUID as the authoritative identity.
# Rules:
# 1) If UUID exists, update current name/platform/last_seen.
# 2) If name exists with a different non-empty UUID, do NOT rebind it. Log collision.
# 3) If name exists with an empty UUID, backfill it with the current UUID.
# 4) Otherwise insert a new player.
identity_register_player:
  type: task
  definitions: player_name|uuid|platform
  debug: false
  script:
    - ~sql id:identity_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 1t

    - define uuid_query "SELECT player_name, uuid, platform, permission_level FROM known_players WHERE uuid='<[uuid]>' LIMIT 1"
    - ~sql id:identity_<queue.id> "query:<[uuid_query]>" save:uuid_check
    - define uuid_rows <entry[uuid_check].result_map>

    - define name_query "SELECT player_name, uuid, platform, permission_level FROM known_players WHERE player_name='<[player_name]>' LIMIT 1"
    - ~sql id:identity_<queue.id> "query:<[name_query]>" save:name_check
    - define name_rows <entry[name_check].result_map>

    # UUID already known: UUID wins. Refuse only if the desired name is already bound to another UUID.
    - if <[uuid_rows].size> > 0:
      - if <[name_rows].size> > 0:
        - define name_uuid <[name_rows].get[1].get[uuid].if_null[]>
        - if <[name_uuid].length> > 0 && <[name_uuid]> != <[uuid]>:
          - announce "<&c>[IDENTITY] NAME COLLISION: <[player_name]> attempted UUID <[uuid]>, but DB name is bound to <[name_uuid]>. Registration not changed." to_console
          - log "text:NAME_COLLISION player_name=<[player_name]> current_uuid=<[uuid]> stored_uuid=<[name_uuid]> platform=<[platform]>" type:warning file:logs/identity_audit.log
          - sql disconnect id:identity_<queue.id>
          - determine collision
      - define update_uuid_query "UPDATE known_players SET player_name='<[player_name]>', platform='<[platform]>', last_seen_at=NOW() WHERE uuid='<[uuid]>' LIMIT 1"
      - ~sql id:identity_<queue.id> "update:<[update_uuid_query]>"
      - announce "<&7>[IDENTITY] UUID match for <[player_name]> (<[uuid]>); record refreshed." to_console
      - sql disconnect id:identity_<queue.id>
      - determine match

    # UUID is new but this name already exists.
    - if <[name_rows].size> > 0:
      - define stored_uuid <[name_rows].get[1].get[uuid].if_null[]>
      - if <[stored_uuid].length> < 1:
        - define backfill_query "UPDATE known_players SET uuid='<[uuid]>', platform='<[platform]>', last_seen_at=NOW() WHERE player_name='<[player_name]>' LIMIT 1"
        - ~sql id:identity_<queue.id> "update:<[backfill_query]>"
        - announce "<&e>[IDENTITY] Backfilled UUID for <[player_name]> -> <[uuid]>" to_console
        - log "text:UUID_BACKFILL player_name=<[player_name]> uuid=<[uuid]> platform=<[platform]>" type:info file:logs/identity_audit.log
        - sql disconnect id:identity_<queue.id>
        - determine backfilled
      - if <[stored_uuid]> != <[uuid]>:
        - announce "<&c>[IDENTITY] UUID MISMATCH: <[player_name]> joined as <[uuid]>, DB has <[stored_uuid]>. Existing identity preserved." to_console
        - log "text:UUID_MISMATCH player_name=<[player_name]> current_uuid=<[uuid]> stored_uuid=<[stored_uuid]> platform=<[platform]>" type:warning file:logs/identity_audit.log
        - sql disconnect id:identity_<queue.id>
        - determine mismatch

    # New UUID and new name.
    - define insert_query "INSERT INTO known_players (player_name, uuid, platform, first_seen_at, last_seen_at) VALUES ('<[player_name]>', '<[uuid]>', '<[platform]>', NOW(), NOW())"
    - ~sql id:identity_<queue.id> "update:<[insert_query]>"
    - announce "<&a>[IDENTITY] Registered new player <[player_name]> (<[uuid]>) platform=<[platform]>" to_console
    - sql disconnect id:identity_<queue.id>
    - determine created

# Admin command for checking the executing player's live identity against known_players.
# Optional name argument performs a database-only lookup for another stored player.
identity_audit_command:
  type: command
  name: identityaudit
  aliases: idaudit
  description: Audit Minecraft Church player identity records
  usage: /identityaudit (player_name)
  permission: minecraftchurch.admin
  script:
    - if <context.source_type> != player:
      - narrate "<&c>Run this command in-game."
      - determine cancelled

    - if <context.args.size> > 0:
      - define lookup_name <context.args.get[1]>
      - ~sql id:identityaudit_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
      - wait 1t
      - define lookup_query "SELECT player_name, uuid, platform, permission_level, first_seen_at, last_seen_at FROM known_players WHERE player_name='<[lookup_name]>' LIMIT 5"
      - ~sql id:identityaudit_<queue.id> "query:<[lookup_query]>" save:lookup_check
      - define lookup_rows <entry[lookup_check].result_map>
      - sql disconnect id:identityaudit_<queue.id>
      - narrate "<&e>=== Identity Audit: <[lookup_name]> ==="
      - if <[lookup_rows].size> < 1:
        - narrate "<&c>No known_players row found."
        - determine cancelled
      - foreach <[lookup_rows]> as:row:
        - narrate "<&7>Name: <&f><[row].get[player_name].if_null[]>"
        - narrate "<&7>UUID: <&f><[row].get[uuid].if_null[]>"
        - narrate "<&7>Platform: <&f><[row].get[platform].if_null[unknown]>"
        - narrate "<&7>Permission: <&f><[row].get[permission_level].if_null[guest]>"
        - narrate "<&7>Last seen: <&f><[row].get[last_seen_at].if_null[unknown]>"
        - narrate "<&8>---"
      - determine cancelled

    - define live_name <player.name>
    - define live_uuid <player.uuid>
    - define live_platform "java"
    - if <[live_uuid].starts_with[00000000-0000-0000-0009-]>:
      - define live_platform "bedrock"

    - ~sql id:identityaudit_<queue.id> connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 1t
    - define by_uuid_query "SELECT player_name, uuid, platform, permission_level FROM known_players WHERE uuid='<[live_uuid]>' LIMIT 5"
    - ~sql id:identityaudit_<queue.id> "query:<[by_uuid_query]>" save:by_uuid
    - define uuid_rows <entry[by_uuid].result_map>
    - define by_name_query "SELECT player_name, uuid, platform, permission_level FROM known_players WHERE player_name='<[live_name]>' LIMIT 5"
    - ~sql id:identityaudit_<queue.id> "query:<[by_name_query]>" save:by_name
    - define name_rows <entry[by_name].result_map>
    - sql disconnect id:identityaudit_<queue.id>

    - narrate "<&e>=== Minecraft Church Identity Audit ==="
    - narrate "<&7>Live name: <&f><[live_name]>"
    - narrate "<&7>Live UUID: <&f><[live_uuid]>"
    - narrate "<&7>Detected platform: <&f><[live_platform]>"
    - narrate "<&7>DB rows by UUID: <&f><[uuid_rows].size>"
    - narrate "<&7>DB rows by name: <&f><[name_rows].size>"

    - if <[uuid_rows].size> < 1 && <[name_rows].size> < 1:
      - narrate "<&c>STATUS: NOT REGISTERED"
      - determine cancelled

    - if <[uuid_rows].size> > 0:
      - define uuid_name <[uuid_rows].get[1].get[player_name].if_null[]>
      - if <[uuid_name]> != <[live_name]>:
        - narrate "<&e>STATUS: UUID MATCH / NAME CHANGED"
        - narrate "<&7>DB name for this UUID: <&f><[uuid_name]>"
      - else:
        - narrate "<&a>STATUS: UUID MATCH"

    - if <[name_rows].size> > 0:
      - define stored_uuid <[name_rows].get[1].get[uuid].if_null[]>
      - narrate "<&7>DB UUID for this name: <&f><[stored_uuid]>"
      - if <[stored_uuid].length> > 0 && <[stored_uuid]> != <[live_uuid]>:
        - narrate "<&c>STATUS: NAME COLLISION / UUID MISMATCH"
        - log "text:MANUAL_AUDIT_MISMATCH player_name=<[live_name]> current_uuid=<[live_uuid]> stored_uuid=<[stored_uuid]>" type:warning file:logs/identity_audit.log

    - if <[uuid_rows].size> > 0:
      - narrate "<&7>DB platform: <&f><[uuid_rows].get[1].get[platform].if_null[unknown]>"
      - narrate "<&7>DB permission: <&f><[uuid_rows].get[1].get[permission_level].if_null[guest]>"
