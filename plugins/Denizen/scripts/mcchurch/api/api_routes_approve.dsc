mcchurch_api_approve_request:
  type: world
  debug: false
  events:

    on webserver web request port:8081 path:/api/approve method:get:
    - run mcchurch_sql_connect

    - define q <context.query>
    - define token <[q].get[token]>
    - define id <[q].get[id]>

    # Validate query params
    - if <[token].is_empty||true> || <[id].is_empty||true>:
      - run mcchurch_api_json_error code:400 error:missing_id_or_token
      - stop

    # Check token against secret (in secrets.secret)
    - if <[token].is[!=].to[<secret[api_approve_token]>]>:
      - run mcchurch_api_json_error code:403 error:invalid_token
      - stop

    # Load verification_request
    - ~sql id:mcchurch
          "query:SELECT id, child_name, adult_name, adult_join, status
           FROM verification_requests
           WHERE id = <[id]>
           LIMIT 1;"
          save:req_q

    - if <entry[req_q].result.is_empty||true>:
      - run mcchurch_api_json_error code:404 error:request_not_found
      - stop

    - define row <entry[req_q].result.get[1]>
    - define child_name <[row].get[child_name]>
    - define adult_name <[row].get[adult_name]>
    - define adult_join <[row].get[adult_join]>
    - define status <[row].get[status]>

    # Already approved? return idempotent ok
    - if <[status].is[==].to[approved]>:
      - definemap resp
          ok:true
          status:already_approved
          id:<[id]>
      - run mcchurch_api_json_ok map:<[resp]>
      - stop

    # Mark request approved
    - ~sql id:mcchurch
          "update:UPDATE verification_requests
           SET status='approved',
               approved_by='api_token',
               approved_at=NOW()
           WHERE id = <[id]>;"
          save:req_upd

    # Insert child group grant
    - ~sql id:mcchurch
          "update:INSERT INTO access_grants
           (request_id, player_name, grant_type, grant_value, status)
           VALUES (
             <[id]>,
             '<[child_name]>',
             'group',
             'child',
             'approved'
           );"
          save:grant_child

    # Optional: adult group grant
    - if <[adult_join].to_string.is[==].to[1]> && <[adult_name].is_empty.not>:
      - ~sql id:mcchurch
            "update:INSERT INTO access_grants
             (request_id, player_name, grant_type, grant_value, status)
             VALUES (
               <[id]>,
               '<[adult_name]>',
               'group',
               'adult',
               'approved'
             );"
            save:grant_adult

    # Optional: if you later add volunteer checkbox, insert a permission grant here

    - definemap resp
        ok:true
        id:<[id]>
        status:approved
    - run mcchurch_api_json_ok map:<[resp]>
