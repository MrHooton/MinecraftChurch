# Fix: XAMPP MySQL Shutdown Unexpectedly

## Common Causes
1. Port 3306 already in use
2. Corrupted MySQL data files
3. Corrupted log files
4. Permission issues
5. Missing or corrupted configuration files

---

## Solution 1: Check MySQL Error Log (Start Here)

The error log will tell you exactly what's wrong.

1. **Open XAMPP Control Panel**
2. Click **"Logs"** button next to MySQL
3. Look at the **most recent error messages** at the bottom

**Common error messages and fixes:**

### Error: "Port 3306 is already in use"
→ **Solution:** See Solution 2 below

### Error: "Can't create/write to file" or "Permission denied"
→ **Solution:** See Solution 4 below

### Error: "Table is corrupted" or "Table doesn't exist"
→ **Solution:** See Solution 5 below

### Error: "InnoDB: Database was not shut down normally"
→ **Solution:** See Solution 6 below

---

## Solution 2: Fix Port Conflict

If another program is using port 3306:

### Step 1: Find what's using port 3306
```powershell
netstat -ano | findstr :3306
```

If you see output, note the **PID** (last number).

### Step 2: Check if it's another MySQL
```powershell
tasklist | findstr <PID>
```

### Step 3: Options

**Option A: Stop the other MySQL service**
```powershell
# If it's a Windows MySQL service:
net stop MySQL80
# Or
net stop MySQL
```

**Option B: Change XAMPP MySQL port**
1. Open `C:\xampp\mysql\bin\my.ini` (or `my.cnf`)
2. Find line: `port=3306`
3. Change to: `port=3307`
4. Save file
5. Restart MySQL in XAMPP

---

## Solution 3: Restore MySQL from Backup (Quick Fix)

XAMPP includes a backup MySQL data directory.

### Step 1: Stop MySQL in XAMPP Control Panel

### Step 2: Backup current data (just in case)
```powershell
# Open PowerShell as Administrator
cd C:\xampp\mysql
xcopy /E /I data data_backup_%date:~-4,4%%date:~-7,2%%date:~-10,2%
```

### Step 3: Restore from backup
```powershell
# Delete corrupted data
rmdir /S /Q data

# Copy backup
xcopy /E /I backup data
```

### Step 4: Start MySQL in XAMPP

---

## Solution 4: Fix Permission Issues

### Step 1: Stop MySQL in XAMPP

### Step 2: Check folder permissions
```powershell
# Open PowerShell as Administrator
cd C:\xampp\mysql
icacls data
```

### Step 3: Fix permissions
```powershell
# Give full control to current user
icacls data /grant "%USERNAME%:(OI)(CI)F" /T

# Also check logs folder
icacls ..\apache\logs /grant "%USERNAME%:(OI)(CI)F" /T
```

### Step 4: Start MySQL again

---

## Solution 5: Repair Corrupted Tables

### Step 1: Start MySQL in safe mode

**Open PowerShell as Administrator:**
```powershell
cd C:\xampp\mysql\bin
.\mysqld.exe --skip-grant-tables --console
```

### Step 2: In a NEW PowerShell window
```powershell
cd C:\xampp\mysql\bin
.\mysql.exe -u root
```

### Step 3: Repair all databases
```sql
-- Check which databases exist
SHOW DATABASES;

-- For each database (except system ones), repair:
USE mysql;
REPAIR TABLE user;
REPAIR TABLE db;

-- If you have minecraft_church:
USE minecraft_church;
REPAIR TABLE verification_codes;
REPAIR TABLE verification_requests;
REPAIR TABLE access_grants;
REPAIR TABLE known_players;
REPAIR TABLE audit_log;

EXIT;
```

### Step 4: Close both PowerShell windows
### Step 5: Start MySQL normally in XAMPP

---

## Solution 6: Fix InnoDB Corruption

### Step 1: Stop MySQL in XAMPP

### Step 2: Delete InnoDB log files
```powershell
# Open PowerShell as Administrator
cd C:\xampp\mysql\data
del ib_logfile0
del ib_logfile1
```

### Step 3: Start MySQL in XAMPP

MySQL will recreate these files automatically.

---

## Solution 7: Clean Reinstall (Last Resort)

If nothing else works:

### Step 1: Stop MySQL in XAMPP

### Step 2: Backup your databases
```powershell
# Open PowerShell as Administrator
cd C:\xampp\mysql\bin

# Export any databases you created
.\mysqldump.exe -u root minecraft_church > C:\backup_minecraft_church.sql

# If you have other databases:
.\mysqldump.exe -u root --all-databases > C:\backup_all_databases.sql
```

### Step 3: Delete MySQL data
```powershell
cd C:\xampp\mysql
rmdir /S /Q data
mkdir data
```

### Step 4: Reinitialize MySQL
```powershell
cd C:\xampp\mysql\bin
.\mysqld.exe --initialize-insecure --console
```

### Step 5: Start MySQL in XAMPP

### Step 6: Restore your databases
```powershell
cd C:\xampp\mysql\bin
.\mysql.exe -u root < C:\backup_minecraft_church.sql
```

---

## Solution 8: Check Windows Event Viewer

Sometimes more details are in Windows logs:

1. Press `Win + R`, type `eventvwr.msc`, press Enter
2. Go to **Windows Logs** → **Application**
3. Look for **MySQL** or **MySQL80** errors
4. Read the error message for specific details

---

## Quick Diagnostic Commands

Run these to gather information:

```powershell
# Check if port is in use
netstat -ano | findstr :3306

# Check for MySQL processes
tasklist | findstr mysql

# Check MySQL data directory exists
Test-Path C:\xampp\mysql\data

# Check MySQL binary exists
Test-Path C:\xampp\mysql\bin\mysqld.exe

# Check disk space (corruption can happen if disk is full)
Get-PSDrive C | Select-Object Used,Free

# Check recent error log (last 20 lines)
Get-Content C:\xampp\mysql\data\*.err -Tail 20
```

---

## Prevention Tips

1. **Always stop MySQL properly** - Use "Stop" button in XAMPP, don't force close
2. **Regular backups** - Backup `C:\xampp\mysql\data` folder periodically
3. **Don't run multiple MySQL instances** - Only use XAMPP MySQL or Windows MySQL service, not both
4. **Keep disk space free** - MySQL needs free space for logs and temp files
5. **Run XAMPP as Administrator** - Some permission issues are avoided

---

## Still Not Working?

If none of these solutions work:

1. **Check the exact error** in `C:\xampp\mysql\data\*.err` file
2. **Share the last 20-30 lines** of the error log
3. **Check XAMPP version** - Consider updating to latest version
4. **Try XAMPP MySQL on a different port** (see Solution 2)

---

## Most Common Fix

**In most cases, Solution 6 (delete InnoDB log files) fixes the issue:**

```powershell
# As Administrator:
cd C:\xampp\mysql\data
del ib_logfile0
del ib_logfile1
```

Then start MySQL in XAMPP again.
