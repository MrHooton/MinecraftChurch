mcchurch_api_verify_request:
  type: world
  debug: true

  events:
    # POST /api/verify-request on port 8081
    on webserver web request port:8081 path:/api/verify-request method:post:
    - announce to_console "[mcchurch] VERIFY SCRIPT VERSION: V9"

    # Basic request info
    - define remote_ip <context.remote_address||unknown>
    - define body_text <context.body||>
    - announce to_console "[mcchurch] /api/verify-request from <[remote_ip]> raw_body=<[body_text]>"

    # Guard: empty body
    - if <[body_text].length||0> <= 0:
      - announce to_console "[mcchurch] verify-request ERROR: empty body"
      - define response_json '{"ok":false,"code":400,"error":"empty_body"}'
      - determine code:400
      - determine headers:[Content-Type=application/json]
      - determine raw_text_content:<[response_json]>
      - stop

    # Body comes in as: "json=<urlencoded JSON>"
    # If it's wrapped in json=..., strip that and URL-decode
    - if <[body_text].starts_with[json=]>:
      - define json_encoded <[body_text].after[json=]>
      - define decoded <[json_encoded].url_decode>
    - else:
      - define decoded <[body_text]>

    - announce to_console "[mcchurch] decoded body: <[decoded]>"

    # ---- Manual JSON field parsing (matches what worked in your logs) ----

    # parent_name
    - define tmp_pn <[decoded].after[<&dq>parent_name<&dq><&co> ]>
    - define parent_name <[tmp_pn].after[<&dq>].before[<&dq>]>

    # parent_email
    - define tmp_pe <[decoded].after[<&dq>parent_email<&dq><&co> ]>
    - define parent_email <[tmp_pe].after[<&dq>].before[<&dq>]>

    # consent (true/false)
    - define tmp_con <[decoded].after[<&dq>consent<&dq><&co> ]>
    # tmp_con looks like: "true,\n\"church\": ..."
    - define consent <[tmp_con].starts_with[true]>

    # church
    - define tmp_ch <[decoded].after[<&dq>church<&dq><&co> ]>
    - define church <[tmp_ch].after[<&dq>].before[<&dq>]>

    # child_name
    - define tmp_cn <[decoded].after[<&dq>child_name<&dq><&co> ]>
    - define child_name <[tmp_cn].after[<&dq>].before[<&dq>]>

    # adult_join (true/false)
    - define tmp_aj <[decoded].after[<&dq>adult_join<&dq><&co> ]>
    - define adult_join <[tmp_aj].starts_with[true]>

    # adult_name
    - define tmp_an <[decoded].after[<&dq>adult_name<&dq><&co> ]>
    - define adult_name <[tmp_an].after[<&dq>].before[<&dq>]>

    # code
    - define tmp_code <[decoded].after[<&dq>code<&dq><&co> ]>
    - define code <[tmp_code].after[<&dq>].before[<&dq>]>

    # ---- Convert booleans to ints for DB ----
    - define consent_int 0
    - if <[consent]>:
      - define consent_int 1

    - define adult_join_int 0
    - if <[adult_join]>:
      - define adult_join_int 1

    - announce to_console "[mcchurch] consent parsed=<[consent]> (int=<[consent_int]>)"
    - announce to_console "[mcchurch] adult_join parsed=<[adult_join]> (int=<[adult_join_int]>)"

    - announce to_console "[mcchurch] parsed verify-request:"
    - announce to_console "parent_name=<[parent_name]>"
    - announce to_console "parent_email=<[parent_email]>"
    - announce to_console "consent=<[consent]> (int=<[consent_int]>)"
    - announce to_console "church=<[church]>"
    - announce to_console "child_name=<[child_name]>"
    - announce to_console "adult_join=<[adult_join]> (int=<[adult_join_int]>)"
    - announce to_console "adult_name=<[adult_name]>"
    - announce to_console "code=<[code]>"

    # ---- DB INSERT into verification_requests ----
    # NOTE: assumes /mcsqlconnect has already been run and id:mcchurch is connected.
    - announce to_console "[mcchurch] inserting verification_request row..."

    - ~sql id:mcchurch "update:INSERT INTO verification_requests
      (child_name, adult_name, code, parent_name, parent_email, consent, church, adult_join, status)
      VALUES
      ('<[child_name]>',
       '<[adult_name]>',
       '<[code]>',
       '<[parent_name]>',
       '<[parent_email]>',
       <[consent_int]>,
       '<[church]>',
       <[adult_join_int]>,
       'pending');" save:insert_req

    # Handle SQL error
    - if <entry[insert_req].error||null> != null:
      - announce to_console "[mcchurch] SQL ERROR on verification_requests insert: <entry[insert_req].error>"
      - define response_json '{"ok":false,"code":500,"error":"sql_error"}'
      - determine code:500
      - determine headers:[Content-Type=application/json]
      - determine raw_text_content:<[response_json]>
      - stop

    - define new_id <entry[insert_req].last_insert_id||0>
    - announce to_console "[mcchurch] verification_requests insert OK. new id: <[new_id]>"

    # ---- HTTP Response ----
    - define response_json '{"ok":true,"code":200,"id":<[new_id]>,\"message\":\"received\"}'
    - announce to_console "[mcchurch] verify-request: DONE, sending HTTP 200 JSON"

    - determine code:200
    - determine headers:[Content-Type=application/json]
    - determine raw_text_content:<[response_json]>
