mcchurch_sql_connect:
  type: command
  name: mcconnect
  description: "Connect to MySQL for mcchurch"
  usage: /mcconnect

  script:
    - announce to_console "[mcchurch] Trying to connect SQL 'mcchurch'..."

    - ~sql id:mcchurch connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>

    - if <entry[conn].error||null> != null:
      - announce to_console "[mcchurch] SQL CONNECT ERROR: <entry[conn].error>"
      - narrate "SQL CONNECT ERROR: <entry[conn].error>"
      - stop

    - announce to_console "[mcchurch] SQL connect OK for 'mcchurch'"
    - narrate "SQL connection 'mcchurch' OK."

mcchurch_test_insert:
  type: command
  name: mctestinsert
  description: "Test insert into verification_requests"
  usage: /mctestinsert
  script:
    - announce to_console "[mcchurch] TEST: starting test insert..."
    - ~sql "id:mcchurch" "update:INSERT INTO verification_requests
      (child_name, adult_name, code, parent_name, parent_email, consent, church, adult_join, status)
      VALUES
      ('TestKid',
       'Test Adult',
       'TESSQL',
       'Jane Doe',
       'jane@example.com',
       1,
       'Example Church',
       0,
       'pending');" save:test_insert
    - if <entry[test_insert].error||null> != null:
      - announce to_console "[mcchurch] TEST SQL ERROR: <entry[test_insert].error>"
      - narrate "SQL ERROR: <entry[test_insert].error>"
      - queue clear
    - announce to_console "[mcchurch] TEST insert OK, new id=<entry[test_insert].last_insert_id||unknown>"
    - narrate "Insert OK, new id=<entry[test_insert].last_insert_id||unknown>"
