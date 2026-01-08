# Fix MySQL User Host Issue

## The Problem
Your MySQL user was created as `minecraft_api'@'%127.0.0.1'` but the connection is trying to use `localhost`. MySQL sometimes treats these differently.

## Solution Options

### Option 1: Create User for Both Hosts (Recommended)

Run this SQL in MySQL (as root):

```sql
-- Create user for localhost
CREATE USER IF NOT EXISTS 'minecraft_api'@'localhost' IDENTIFIED BY '000000';
GRANT ALL PRIVILEGES ON minecraft.* TO 'minecraft_api'@'localhost';

-- Create user for 127.0.0.1
CREATE USER IF NOT EXISTS 'minecraft_api'@'127.0.0.1' IDENTIFIED BY '000000';
GRANT ALL PRIVILEGES ON minecraft.* TO 'minecraft_api'@'127.0.0.1';

FLUSH PRIVILEGES;
```

Or use the SQL file:
```bash
mysql -u root -p < database/fix_user_host.sql
```

### Option 2: Change Connection to 127.0.0.1

Update your `.env` file to use `127.0.0.1` instead of `localhost`:

```env
DB_HOST=127.0.0.1
```

### Option 3: Use Existing User

If the user exists as `'minecraft_api'@'%127.0.0.1'`, try connecting with:

```env
DB_HOST=127.0.0.1
```

## Quick Fix

Run this in MySQL (phpMyAdmin SQL tab or command line):

```sql
CREATE USER IF NOT EXISTS 'minecraft_api'@'localhost' IDENTIFIED BY '000000';
GRANT ALL PRIVILEGES ON minecraft.* TO 'minecraft_api'@'localhost';
FLUSH PRIVILEGES;
```

Then test connection again.
