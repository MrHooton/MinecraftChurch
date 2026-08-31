# File: scripts/test_mysql_connection.dsc
# Test script to verify MySQL connection

test_mysql_connection:
  type: command
  name: testmysql
  description: Test MySQL database connection
  usage: /testmysql
  permission: denizen.admin
  script:
    - narrate "<&7>Testing MySQL connection..."
    - narrate "<&7>Attempting to connect to mysql.apexhosting.gdn:3306/apexMC2969109"
    
    # Try to connect
    - ~sql id:test_conn connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
    - wait 1t
    
    # If the connection fails, Denizen will error out; otherwise continue.
    - narrate "<&a>✓ Connected!"
    
    # Try a simple query
    - ~sql id:test_conn "query:SELECT 1 as test" save:test_result
    - define rows <entry[test_result].result_map.if_null[<list[]>]>
    - narrate "<&a>✓ Query test successful! Rows: <[rows].size>"

    # Try to query the known_players table
    - ~sql id:test_conn "query:SELECT COUNT(*) as count FROM known_players" save:count_result
    - define count_rows <entry[count_result].result_map.if_null[<list[]>]>
    - if <[count_rows].size> > 0:
      - define player_count <[count_rows].get[1].get[count].if_null[0]>
      - narrate "<&a>✓ known_players table accessible! Total players: <[player_count]>"
    - else:
      - narrate "<&c>✗ Could not query known_players table"

    - sql disconnect id:test_conn
    - narrate "<&a>✓ Disconnected successfully"
