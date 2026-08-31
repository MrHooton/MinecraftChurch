mcchurch_api_player_seen:
  type: world
  debug: false
  events:

    on webserver web request port:8081 path:/api/player-seen method:post:
    - run mcchurch_sql_connect

    - define raw_body <context.body>
    - if <[raw_body].is_empty||true>:
      - run mcchurch_api_json_error code:400 error:empty_body
      - stop

    - run mcchurch_api_parse_json def:<[raw_body]> save:parsed
    - define body_map <entry[parsed].result>

    - define player_name <[body_map].get[player_name]>
    - define uuid <[body_map].get[uuid]>
    - define platform_raw <[body_map].get[platform].to_lowercase>

    # Normalize platform enum
    - define platform unknown
    - if <[platform_raw].is[==].to[java]>:
      - define platform java
    - if <[platform_raw].is[==].to[bedrock]>:
      - define platform bedrock

    - if <[player_name].is_empty||true>:
      - run mcchurch_api_json_error code:400 error:player_name_required
      - stop

    # Upsert into known_players
    - ~sql id:mcchurch
          "update:INSERT INTO known_players
           (player_name, uuid, platform, permission_level, first_seen_at, last_seen_at)
           VALUES(
             '<[player_name]>',
             '<[uuid]>',
             '<[platform]>',
             'guest',
             NOW(),
             NOW()
           )
           ON DUPLICATE KEY UPDATE
             uuid = VALUES(uuid),
             platform = VALUES(platform),
             last_seen_at = NOW();"
          save:up

    - definemap resp
        ok:true
        player_name:<[player_name]>
        platform:<[platform]>
    - run mcchurch_api_json_ok map:<[resp]>
