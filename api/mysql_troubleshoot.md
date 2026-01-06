# MySQL Connection Troubleshooting for XAMPP

## The Issue
You're getting `ERROR 1045 (28000): Access denied for user 'root'@'localhost'` when trying to connect with password `Star123!@#`.

## Solutions for XAMPP

### Solution 1: Try Without Password (XAMPP Default)
XAMPP's MySQL root user often has **no password by default**. Try:

```powershell
mysql -u root
```

(Don't use `-p` flag, just press Enter when it asks for password, or leave it blank)

### Solution 2: Check if MySQL Service is Running
1. Open **XAMPP Control Panel**
2. Make sure **MySQL** shows as "Running" (green)
3. If not running, click **Start** next to MySQL

### Solution 3: Reset Root Password via XAMPP
If you need to set/reset the root password:

1. **Stop MySQL in XAMPP Control Panel**

2. **Open PowerShell as Administrator** and run:
```powershell
# Navigate to XAMPP MySQL bin directory
cd C:\xampp\mysql\bin

# Start MySQL in safe mode (skip grant tables)
.\mysqld.exe --skip-grant-tables --console
```

3. **Open a NEW PowerShell window** (keep the first one running) and run:
```powershell
cd C:\xampp\mysql\bin
.\mysql.exe -u root
```

4. **In the MySQL prompt**, run:
```sql
USE mysql;
UPDATE user SET authentication_string=PASSWORD('Star123!@#') WHERE User='root';
FLUSH PRIVILEGES;
EXIT;
```

5. **Close both PowerShell windows** and start MySQL normally from XAMPP Control Panel

### Solution 4: Create a New User (Easier Alternative)
If root password reset is complicated, create a new admin user:

1. **Stop MySQL in XAMPP**

2. **Start MySQL in safe mode** (from Administrator PowerShell):
```powershell
cd C:\xampp\mysql\bin
.\mysqld.exe --skip-grant-tables --console
```

3. **In a NEW PowerShell window**:
```powershell
cd C:\xampp\mysql\bin
.\mysql.exe -u root
```

4. **Create new user and grant privileges**:
```sql
CREATE USER 'minecraft_api'@'localhost' IDENTIFIED BY 'YourNewPassword123';
GRANT ALL PRIVILEGES ON *.* TO 'minecraft_api'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;
```

5. **Restart MySQL normally** from XAMPP Control Panel

6. **Test connection**:
```powershell
mysql -u minecraft_api -p
# Enter: YourNewPassword123
```

### Solution 5: Use XAMPP MySQL Default (No Password)
If you just want to get started quickly:

1. Connect without password:
```powershell
mysql -u root
```

2. Create the database and user:
```sql
CREATE DATABASE IF NOT EXISTS minecraft_church CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'minecraft_api'@'localhost' IDENTIFIED BY 'YourSecurePassword123';
GRANT SELECT, INSERT, UPDATE, DELETE ON minecraft_church.* TO 'minecraft_api'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

3. Use these credentials in your `.env`:
   - Username: `minecraft_api`
   - Password: `YourSecurePassword123`

## Quick Test Commands

### Test connection without password:
```powershell
mysql -u root
```

### Test connection with password:
```powershell
mysql -u root -p
# Then enter your password
```

### Test if MySQL is running:
```powershell
netstat -an | findstr 3306
```
You should see `0.0.0.0:3306` if MySQL is running.

### Check XAMPP MySQL status:
Open XAMPP Control Panel and check if MySQL shows as "Running"

## Recommended: Use Dedicated User
Instead of using root, create a dedicated user for the API:

```sql
-- After connecting (without password if XAMPP default)
CREATE USER 'minecraft_api'@'localhost' IDENTIFIED BY 'StrongPassword123!@#';
CREATE DATABASE IF NOT EXISTS minecraft_church CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT SELECT, INSERT, UPDATE, DELETE ON minecraft_church.* TO 'minecraft_api'@'localhost';
FLUSH PRIVILEGES;
```

Then use in your `.env`:
```
DB_USER=minecraft_api
DB_PASSWORD=StrongPassword123!@#
```
