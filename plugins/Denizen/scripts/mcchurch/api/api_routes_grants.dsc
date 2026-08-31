mcchurch_api_grants:
  type: world
  debug: false
  events:

    # C) Return all approved grants
    on webserver web request port:8081 path:/api/grants method:get:
    - run mcchurch_sql_connect

    - define q <context.query>
    - define secret <[q].get[secret]>

    - if <[secret].is_empty||true>:
      - run mcchurch_api_json_error code:400 error:missing_secret
      - stop

    - if <[secret].is[!=].to[<secret[api_grants_secret]>]>:
      - run mcchurch_api_json_error code:403 error:invalid_secret
      - stop

    - ~sql id:mcchurch
          "query:SELECT id, player_name, grant_type, grant_value
           FROM access_grants
           WHERE status='approved'
           ORDER BY id ASC;"
          save:grants_q

    # entry[grants_q].result is ListTag of rows (MapTags)
    - define grants_list <entry[grants_q].result>
    - define json <[grants_list].to_json>

    - determine code:200 passively
    - determine headers:[Content-Type=application/json] passively
    - determine raw_text_content:<[json]>


    # D) Mark given IDs as applied
    on webserver web request port:8081 path:/api/grants/applied method:post:
    - run mcchurch_sql_connect

    - define raw_body <context.body>
    - if <[raw_body].is_empty||true>:
      - run mcchurch_api_json_error code:400 error:empty_body
      - stop

    - run mcchurch_api_parse_json def:<[raw_body]> save:parsed
    - define body_map <entry[parsed].result>
    - define ids_list <[body_map].get[ids]>

    - if <[ids_list].is_empty||true>:
      - run mcchurch_api_json_error code:400 error:no_ids
      - stop

    # Build CSV for SQL IN()
    - define ids_csv <[ids_list].separated_by[, ]>

    - ~sql id:mcchurch
          "update:UPDATE access_grants
           SET status='applied',
               applied_at=NOW()
           WHERE id IN (<[ids_csv]>);"
          save:upd

    - define count <entry[upd].update_count>
    - definemap resp
        ok:true
        updated:<[count]>
    - run mcchurch_api_json_ok map:<[resp]>
