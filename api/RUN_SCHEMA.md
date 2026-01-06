# How to Run the Database Schema

## The Problem
You tried to use `SOURCE` command with `-e` flag, which doesn't work. The `SOURCE` command only works when running MySQL interactively.

## Solution: Use Input Redirection

Instead of using `SOURCE`, pipe the SQL file directly to MySQL:

### Option 1: Using root user (easiest)

```powershell
# Make sure you're in the project root directory
cd C:\Users\codeforces_master\Documents\MinecraftChurch

# Run the schema file
C:\xampp\mysql\bin\mysql.exe -u root minecraft_church < database\schema.sql
```

### Option 2: Using minecraft_api user (if it exists)

```powershell
# Make sure you're in the project root directory
cd C:\Users\codeforces_master\Documents\MinecraftChurch

# Run the schema file (will prompt for password)
C:\xampp\mysql\bin\mysql.exe -u minecraft_api -p minecraft_church < database\schema.sql
```

When prompted, enter the password you set when creating the user.

---

## Step-by-Step Complete Setup

### Step 1: Connect as root to create user (if not created yet)

```powershell
C:\xampp\mysql\bin\mysql.exe -u root
```

Then in MySQL:

```sql
-- Create database (if not exists)
CREATE DATABASE IF NOT EXISTS minecraft_church 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Create user
CREATE USER 'minecraft_api'@'localhost' IDENTIFIED BY 'YourSecurePassword123';

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON minecraft_church.* TO 'minecraft_api'@'localhost';

-- Apply changes
FLUSH PRIVILEGES;

-- Exit
EXIT;
```

### Step 2: Run the schema

```powershell
# From project root
cd C:\Users\codeforces_master\Documents\MinecraftChurch

# Run schema as root (easiest)
C:\xampp\mysql\bin\mysql.exe -u root minecraft_church < database\schema.sql

# OR run as minecraft_api user
C:\xampp\mysql\bin\mysql.exe -u minecraft_api -p minecraft_church < database\schema.sql
```

### Step 3: Verify tables were created

```powershell
C:\xampp\mysql\bin\mysql.exe -u root minecraft_church -e "SHOW TABLES;"
```

You should see:
```
+----------------------------+
| Tables_in_minecraft_church |
+----------------------------+
| access_grants              |
| audit_log                  |
| known_players              |
| verification_codes         |
| verification_requests      |
+----------------------------+
```

### Step 4: Verify table structure

```powershell
C:\xampp\mysql\bin\mysql.exe -u root minecraft_church -e "DESCRIBE verification_codes;"
```

---

## Using SOURCE Command (Interactive Mode)

If you want to use the `SOURCE` command, you need to run MySQL interactively:

```powershell
# Connect to MySQL
C:\xampp\mysql\bin\mysql.exe -u root minecraft_church

# Then inside MySQL prompt:
SOURCE C:/Users/codeforces_master/Documents/MinecraftChurch/database/schema.sql;

# Or use relative path (must be exact path):
SOURCE database/schema.sql;

# Verify
SHOW TABLES;

# Exit
EXIT;
```

**Note:** Use forward slashes `/` in the SOURCE command path, even on Windows.

---

## Troubleshooting

### Error: "Access denied for user"
- Make sure MySQL is running in XAMPP
- Check username and password are correct
- Try connecting as root first (no password usually)

### Error: "Unknown database"
- Create the database first (see Step 1 above)

### Error: "Table already exists"
- Tables already exist, which is fine
- Or drop them first: `DROP DATABASE minecraft_church; CREATE DATABASE minecraft_church ...;`

---

## Quick Copy-Paste Commands

**Run schema as root:**
```powershell
cd C:\Users\codeforces_master\Documents\MinecraftChurch
C:\xampp\mysql\bin\mysql.exe -u root minecraft_church < database\schema.sql
```

**Verify it worked:**
```powershell
C:\xampp\mysql\bin\mysql.exe -u root minecraft_church -e "SHOW TABLES;"
```
