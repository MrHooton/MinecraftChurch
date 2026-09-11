# MySQL diagnostic commands for Minecraft Church.
# Uses only SQL command result tags documented in the Denizen command reference.

mcchurch_sql_connect:
  type: command
  name: mcconnect
  description: "Connect to MySQL for mcchurch"
  usage: /mcconnect
  permission: minecraftchurch.admin
  script:
    - announce to_console "[mcchurch] Trying to connect SQL 'mcchurch'..."
    - ~sql id:mcchurch connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - if !<util.sql_connections.contains[mcchurch]>:
      - announce to_console "[mcchurch] SQL connection was not registered."
      - narrate "<&c>SQL connection failed. Check the Denizen console error for details."
      - stop
    - announce to_console "[mcchurch] SQL connect OK for 'mcchurch'"
    - narrate "<&a>SQL connection 'mcchurch' OK."

mcchurch_test_insert:
  type: command
  name: mctestinsert
  description: "Test insert into verification_requests"
  usage: /mctestinsert
  permission: minecraftchurch.admin
  script:
    - if !<util.sql_connections.contains[mcchurch]>:
      - narrate "<&7>No mcchurch SQL connection is open. Connecting..."
      - ~sql id:mcchurch connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - if !<util.sql_connections.contains[mcchurch]>:
      - narrate "<&c>SQL connection failed. Check the Denizen console error for details."
      - stop

    - announce to_console "[mcchurch] TEST: starting test insert..."
    - ~sql id:mcchurch "update:INSERT INTO verification_requests (child_name, adult_name, code, parent_name, parent_email, consent, church, adult_join, status) VALUES ('TestKid', 'Test Adult', 'TESSQL', 'Jane Doe', 'jane@example.com', 1, 'Example Church', 0, 'pending');" save:test_insert
    - define affected <entry[test_insert].affected_rows.if_null[0]>
    - if <[affected]> < 1:
      - announce to_console "[mcchurch] TEST insert completed but affected 0 rows."
      - narrate "<&c>Insert did not affect a row. Check the console for SQL errors."
      - stop
    - announce to_console "[mcchurch] TEST insert OK; affected_rows=<[affected]>"
    - narrate "<&a>Insert OK. Rows affected: <[affected]>"
