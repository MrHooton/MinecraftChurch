# Local MySQL Setup Guide (Testing)

This guide helps you set up a local MySQL server for testing your verification system.

## Option 1: XAMPP (Easiest for Windows)

### Step 1: Install XAMPP
1. Download XAMPP: https://www.apachefriends.org/download.html
2. Install it (default location: `C:\xampp`)
3. Start XAMPP Control Panel

### Step 2: Start MySQL
1. Open XAMPP Control Panel
2. Click "Start" next to MySQL
3. Wait until it shows "Running" (green)

### Step 3: Create Database and User
1. Open phpMyAdmin: http://localhost/phpmyadmin
2. Click "New" in left sidebar
3. Database name: `minecraft_church`
4. Collation: `utf8mb4_unicode_ci`
5. Click "Create"

### Step 4: Create Database User (Optional but Recommended)
1. In phpMyAdmin, click "User accounts" tab
2. Click "Add user account"
3. Username: `minecraft_api`
4. Hostname: `localhost`
5. Password: Enter a password (remember it!)
6. Click "Create user"

### Step 5: Grant Permissions
1. Still in "User accounts", find your new user
2. Click "Edit privileges"
3. Select database: `minecraft_church`
4. Check all privileges or at minimum:
   - SELECT
   - INSERT
   - UPDATE
   - DELETE
   - CREATE
   - ALTER
   - INDEX
5. Click "Go"

### Step 6: Import Schema
1. In phpMyAdmin, select `minecraft_church` database
2. Click "Import" tab
3. Click "Choose File"
4. Select: `database/schema.sql`
5. Click "Go"
6. Verify tables were created (should see 5 tables)

---

## Option 2: MySQL Standalone (More Control)

### Step 1: Install MySQL
1. Download MySQL Installer: https://dev.mysql.com/downloads/installer/
2. Choose "Developer Default" or "Server only"
3. During installation:
   - Set root password (remember it!)
   - Make note of port (default: 3306)

### Step 2: Create Database
Open MySQL Command Line Client or MySQL Workbench and run:

```sql
CREATE DATABASE minecraft_church 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;
```

### Step 3: Create User (Optional)
```sql
CREATE USER 'minecraft_api'@'localhost' IDENTIFIED BY 'your_password_here';
GRANT ALL PRIVILEGES ON minecraft_church.* TO 'minecraft_api'@'localhost';
FLUSH PRIVILEGES;
```

### Step 4: Import Schema
From command line:
```bash
mysql -u root -p minecraft_church < database/schema.sql
```

Or use MySQL Workbench:
1. Open MySQL Workbench
2. Connect to localhost
3. Select `minecraft_church` database
4. File → Run SQL Script
5. Select `database/schema.sql`
6. Execute

---

## Option 3: Docker (Advanced)

### Step 1: Run MySQL Container
```bash
docker run --name mysql-minecraft-church \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=minecraft_church \
  -e MYSQL_USER=minecraft_api \
  -e MYSQL_PASSWORD=testpassword \
  -p 3306:3306 \
  -d mysql:8.0 \
  --character-set-server=utf8mb4 \
  --collation-server=utf8mb4_unicode_ci
```

### Step 2: Import Schema
```bash
docker exec -i mysql-minecraft-church mysql -uminecraft_api -ptestpassword minecraft_church < database/schema.sql
```

---

## Configure Your .env File

After setting up MySQL, update `api/.env`:

### If using root user:
```env
DB_HOST=localhost
DB_PORT=3306
DB_NAME=minecraft_church
DB_USER=root
DB_PASSWORD=your_root_password_here
DB_SSL=false
```

### If using minecraft_api user:
```env
DB_HOST=localhost
DB_PORT=3306
DB_NAME=minecraft_church
DB_USER=minecraft_api
DB_PASSWORD=your_user_password_here
DB_SSL=false
```

---

## Test Connection

After configuration, test:
```bash
cd api
node test-connection.js
```

You should see:
```
✅ Database connection successful!
✅ Query test successful!
✅ Found 5 table(s) in database:
   - verification_codes
   - verification_requests
   - access_grants
   - known_players
   - audit_log
✅ All tests passed! Your database is ready to use.
```

---

## Troubleshooting

### MySQL Service Not Running
- **XAMPP**: Make sure MySQL is "Running" in XAMPP Control Panel
- **Windows Service**: Check services.msc, find MySQL service, start it
- **Command**: `net start MySQL` (may need admin)

### Access Denied Error
- Verify username and password in `.env`
- If using root, make sure password is correct
- Try connecting with MySQL client first to verify credentials

### Can't Connect to localhost
- Verify MySQL is running
- Check port (default: 3306)
- Try `127.0.0.1` instead of `localhost` in `.env`

### Database Doesn't Exist
- Create it first (see steps above)
- Verify database name in `.env` matches exactly

### Schema Import Failed
- Check `database/schema.sql` file exists
- Verify you're importing to correct database
- Check for SQL errors in import output

---

## Quick Start (XAMPP)

If you just want to get started quickly with XAMPP:

1. Install XAMPP
2. Start MySQL in XAMPP
3. Open phpMyAdmin: http://localhost/phpmyadmin
4. Create database `minecraft_church`
5. Import `database/schema.sql`
6. Update `.env` with:
   ```env
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD= (leave empty if no root password)
   DB_NAME=minecraft_church
   ```
7. Test: `node test-connection.js`

That's it! 🚀
