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
      ('TestKiad',
       'Test Adult',
       'TESSwL',
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
