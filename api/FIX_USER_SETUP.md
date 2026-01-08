# Fix MySQL User Setup

## The Problem
The user `minecraft_api` either doesn't exist or doesn't have the right permissions.

## Solution: Create the User

### Option 1: Using phpMyAdmin

1. Open phpMyAdmin: http://localhost/phpmyadmin
2. Click "SQL" tab
3. Run this SQL:

```sql
CREATE USER IF NOT EXISTS 'minecraft_api'@'localhost' IDENTIFIED BY '000000';
GRANT ALL PRIVILEGES ON minecraft.* TO 'minecraft_api'@'localhost';
FLUSH PRIVILEGES;
```

### Option 2: Using MySQL Command Line

1. Open MySQL Command Line Client (or terminal)
2. Log in as root:
   ```bash
   mysql -u root -p
   ```
3. Enter root password when prompted
4. Run these commands:

```sql
CREATE USER IF NOT EXISTS 'minecraft_api'@'localhost' IDENTIFIED BY '000000';
GRANT ALL PRIVILEGES ON minecraft.* TO 'minecraft_api'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Option 3: Using SQL File

1. Open MySQL as root:
   ```bash
   mysql -u root -p
   ```
2. Run the SQL file:
   ```sql
   SOURCE database/create_user.sql;
   ```
   Or from command line:
   ```bash
   mysql -u root -p < database/create_user.sql
   ```

## Alternative: Use Root User (Quick Test)

If you just want to test quickly, you can use root user in your `.env`:

```env
DB_USER=root
DB_PASSWORD=your_root_password
```

Then later create the proper user for production.

## Verify User Was Created

After creating the user, test connection:
```bash
cd api
node test-connection.js
```

Or test directly with MySQL:
```bash
mysql -u minecraft_api -p000000 minecraft
```

If that works, the user is set up correctly!

## Troubleshooting

### User Already Exists But Password Wrong
If user exists but password is wrong, reset it:
```sql
ALTER USER 'minecraft_api'@'localhost' IDENTIFIED BY '000000';
FLUSH PRIVILEGES;
```

### User Exists But No Permissions
Grant permissions again:
```sql
GRANT ALL PRIVILEGES ON minecraft.* TO 'minecraft_api'@'localhost';
FLUSH PRIVILEGES;
```

### User Created But Still Can't Connect
Check if user was created for correct host:
```sql
SELECT user, host FROM mysql.user WHERE user = 'minecraft_api';
```

Should show: `minecraft_api` | `localhost`

If it shows a different host (like `%` or `127.0.0.1`), you may need to create for that host or use that host in connection.
