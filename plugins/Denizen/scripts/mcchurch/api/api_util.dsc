mcchurch_api_json_error:
  type: task
  debug: false
  definitions: code|error
  script:
  # code  = HTTP status (eg 400, 429)
  # error = short machine-readable error key (eg empty_body)
  - define status <[code]||400>
  - define err <[error]||internal_error>

  - define resp_map <map[ok=false|error=<[err]>]>
  - define json <[resp_map].to_json>

  - determine passively code:<[status]>
  - determine passively headers:li@Content-Type=application/json
  - determine raw_text_content:<[json]>


mcchurch_api_parse_json:
  type: task
  debug: false
  definitions: body
  script:
  # Parse JSON request body into a MapTag
  - define text <[body]||>
  - if <[text].length.is_less_than[1]>:
    - determine <map[]>
    - stop
  # text should now be a JSON string
  - define parsed <[text].as[json].to_map>
  - determine <[parsed]>


mcchurch_api_rate_limit_verify:
  type: task
  debug: false
  definitions: ip
  script:
  # Simple stub: always allow
  # Later you can replace this with real per-IP rate limiting logic.
  - determine ok
