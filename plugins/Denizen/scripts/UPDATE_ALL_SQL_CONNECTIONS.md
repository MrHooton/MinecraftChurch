# SQL Connection Update Guide

## Summary
The event-driven SQL error handler (`sql_error_handler.dsc`) is now active and will automatically:
- Catch all SQL connection errors
- Log them to `logs/sql_errors.log`
- Notify online admins when errors occur
- Clean up stale connections every 5 minutes
- Provide automatic retry logic

## Files Updated
✅ `verification_storage_mysql.dsc` - All 6 connection points updated with retry wrapper
✅ `sql_error_handler.dsc` - NEW file with event handler and retry wrapper
✅ `test_mysql_connection.dsc` - Test script for debugging

## Files That Still Need Updating
⚠️ `two_person_safeguard.dsc` - 4 connection points
⚠️ `safeguard_admin_monitor.dsc` - 2 connection points  
⚠️ `permission_admin.dsc` - 2 connection points
⚠️ `admin_approval.dsc` - 6 connection points
⚠️ `grant_applicator.dsc` - 4 connection points
⚠️ `doorkeeper_fixed.dsc` - 1 connection point

## How It Works Now

### Old Pattern (will still work but no retry):
```
- ~sql id:db_conn connect:mysql.apexhosting.gdn:3306/apexMC2969109 username:apexMC2969109 password:<secret[mysql_password]>
- wait 2s
```

### New Pattern (with automatic retry):
```
- ~run sql_connect_with_retry def:db_conn|3 save:conn_success
- if <entry[conn_success].result||false> == false:
  - stop  # or determine null, or whatever makes sense
```

## Benefits
1. **Event-Driven**: Errors are caught automatically by the world event
2. **Automatic Retry**: 3 attempts with 1s delay between each
3. **Admin Notifications**: Online admins get instant notification of SQL errors
4. **Centralized Logging**: All SQL errors go to one log file
5. **Connection Cleanup**: Stale connections cleaned up every 5 minutes
6. **User-Friendly**: Players get helpful messages instead of silent failures

## What Happens When Connection Fails
1. `sql_connect_with_retry` tries to connect (attempt 1)
2. If it fails, waits 1s and tries again (attempt 2)
3. If it fails again, waits 1s and tries again (attempt 3)
4. If all 3 attempts fail:
   - Logs to `logs/sql_errors.log`
   - The event handler catches the error and notifies admins
   - Returns false to the caller
   - The script stops gracefully with a user-friendly message
