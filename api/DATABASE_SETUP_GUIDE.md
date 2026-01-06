# MySQL Database Setup Guide

This guide will help you get or create MySQL database credentials for the Minecraft Church Verification System API.

## Step 1: Check if MySQL is Installed

### Option A: Check via Command Line
```powershell
# Check if MySQL is installed
mysql --version

# OR check if MySQL service is running
Get-Service | Where-Object {$_.DisplayName -like "*MySQL*"}
```

### Option B: Check via Windows Services
1. Press `Win + R`, type `services.msc`, press Enter
2. Look for "MySQL" services

### Option C: Check if MySQL Workbench is installed
If you have MySQL Workbench installed, you likely have MySQL server too.

## Step 2: Install MySQL (If Not Installed)

### Option 1: Install MySQL Community Server (Recommended)
1. **Download MySQL**: Go to https://dev.mysql.com/downloads/mysql/
   - Choose "MySQL Community Server"
   - Download the Windows installer (.msi)
   - Choose the appropriate version (8.0+ recommended)

2. **Install MySQL**:
   - Run the installer
   - Choose "Developer Default" or "Server only"
   - During installation, you'll be prompted to set a **root password** - **SAVE THIS!**
   - Complete the installation

3. **Verify Installation**:
   ```powershell
   mysql --version
   ```

### Option 2: Use XAMPP (Easier for Development)
1. **Download XAMPP**: https://www.apachefriends.org/
2. **Install XAMPP**:
   - During installation, you can set a MySQL root password
   - Or it defaults to empty password for root (less secure)
3. **Start MySQL**:
   - Open XAMPP Control Panel
   - Click "Start" next to MySQL

### Option 3: Use Remote Database Hosting
If you prefer to host the database remotely:
- **Free Options**: Free tier of cloud databases (AWS RDS, Azure, etc.)
- **Hosting Providers**: Many web hosts provide MySQL databases
- You'll get credentials from your hosting provider

## Step 3: Access MySQL and Get/Create Credentials

### Method A: Using MySQL Command Line

1. **Open Command Prompt or PowerShell**

2. **Connect to MySQL**:
   ```powershell
   # If you set a root password during installation:
   mysql -u root -p
   # Enter your root password when prompted
   
   # If no password (XAMPP default):
   mysql -u root
   ```

3. **Check existing users** (optional):
   ```sql
   SELECT user, host FROM mysql.user;
   ```

4. **Create a dedicated database user** (recommended for security):
   ```sql
   -- Create a new user specifically for the API
   CREATE USER 'minecraft_api'@'localhost' IDENTIFIED BY 'your_secure_password_here';
   
   -- Grant permissions only to the minecraft_church database
   GRANT SELECT, INSERT, UPDATE, DELETE ON minecraft_church.* TO 'minecraft_api'@'localhost';
   
   -- Apply the changes
   FLUSH PRIVILEGES;
   ```

5. **Use the new credentials**:
   - Username: `minecraft_api`
   - Password: `your_secure_password_here` (the one you just set)

6. **Or use root (less secure, only for development)**:
   - Username: `root`
   - Password: The password you set during MySQL installation

### Method B: Using MySQL Workbench (GUI Tool)

1. **Open MySQL Workbench**

2. **Connect to your MySQL server**:
   - Click on the existing connection (or create new)
   - Enter password for root user

3. **Create a new user**:
   - Go to "Server" → "Users and Privileges"
   - Click "Add Account"
   - Login name: `minecraft_api`
   - Authentication: `Standard`
   - Password: Set a strong password
   - Click "Apply"

4. **Grant privileges**:
   - Select the user you just created
   - Go to "Schema Privileges" tab
   - Click "Add Entry"
   - Select "minecraft_church" database
   - Grant: SELECT, INSERT, UPDATE, DELETE
   - Click "Apply"

5. **Test the connection**:
   - Create a new connection with the new user credentials
   - Verify you can connect

### Method C: Using phpMyAdmin (If using XAMPP)

1. **Start Apache and MySQL in XAMPP Control Panel**

2. **Open phpMyAdmin**:
   - Go to http://localhost/phpmyadmin
   - Login with:
     - Username: `root`
     - Password: (empty if default, or your password)

3. **Create a new user**:
   - Click "User accounts" tab
   - Click "Add user account"
   - Username: `minecraft_api`
   - Password: Set a secure password
   - Host name: `localhost`
   - Under "Database for user account", select "Grant all privileges on database 'minecraft_church'"
   - Click "Go"

## Step 4: Create the Database (If Not Already Created)

1. **Connect to MySQL** (using any method above)

2. **Create the database**:
   ```sql
   CREATE DATABASE IF NOT EXISTS minecraft_church 
   CHARACTER SET utf8mb4 
   COLLATE utf8mb4_unicode_ci;
   ```

3. **Run the schema**:
   ```powershell
   # From the project root directory:
   mysql -u minecraft_api -p minecraft_church < database/schema.sql
   # Enter your password when prompted
   ```

4. **Verify tables were created**:
   ```sql
   USE minecraft_church;
   SHOW TABLES;
   ```
   
   You should see:
   - `verification_codes`
   - `verification_requests`
   - `access_grants`
   - `known_players`
   - `audit_log`

## Step 5: Update Your API Configuration

1. **Copy the template file**:
   ```powershell
   cd api
   copy env.template .env
   ```

2. **Edit `.env` file** and update:
   ```env
   DB_USER=minecraft_api
   DB_PASSWORD=your_secure_password_here
   ```

3. **Test the connection** (after implementing API endpoints):
   - Run the API server
   - Check logs for connection errors

## Troubleshooting

### "mysql: command not found"
- MySQL is not in your PATH
- Try: `C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe -u root -p`
- Or add MySQL to your system PATH

### "Access denied for user"
- Wrong password: Double-check your password
- User doesn't exist: Create the user first (see Step 3)
- User doesn't have permissions: Grant permissions (see Step 3)

### "Unknown database 'minecraft_church'"
- Database doesn't exist: Create it first (see Step 4)

### "Can't connect to MySQL server"
- MySQL service not running:
  - XAMPP: Start MySQL in XAMPP Control Panel
  - Windows Service: Start "MySQL80" service in services.msc
  - Or run: `net start MySQL80`

### Forgot Root Password

**Windows (MySQL 8.0+)**:
1. Stop MySQL service: `net stop MySQL80`
2. Create a text file `C:\mysql-init.txt`:
   ```
   ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
   ```
3. Start MySQL with init file:
   ```powershell
   "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe" --init-file=C:\mysql-init.txt
   ```
4. MySQL will reset the password
5. Delete `C:\mysql-init.txt`
6. Restart MySQL service normally

## Security Best Practices

1. **Never use root for application connections**
   - Create a dedicated user with limited permissions
   - Only grant necessary privileges (SELECT, INSERT, UPDATE, DELETE)

2. **Use strong passwords**
   - Minimum 12 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - Don't reuse passwords

3. **Limit user access**
   - Only grant access from `localhost` for local databases
   - Only grant access to specific databases

4. **For production**:
   - Use SSL connections
   - Enable firewall rules
   - Regular backups
   - Monitor access logs

## Quick Reference

### Default MySQL Port
- **3306** (default)
- Can be changed in MySQL configuration

### Common Defaults
- **XAMPP**: Username `root`, Password (empty)
- **MySQL Installer**: You set password during installation
- **Remote Hosting**: Check with your hosting provider

### Connection String Format
```
mysql://username:password@host:port/database
```

Example:
```
mysql://minecraft_api:MySecureP@ss123@localhost:3306/minecraft_church
```

## Next Steps

Once you have your credentials:
1. ✅ Update `api/.env` with your database credentials
2. ⏳ Test the connection (after implementing API endpoints)
3. ⏳ Continue with API endpoint implementation
