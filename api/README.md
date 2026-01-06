# Apex API - Database Configuration Guide

This directory contains configuration files for the Minecraft Church Verification System API.

## Quick Start

1. **Choose your configuration format**:
   - `.env` - For Node.js/Python/any framework using environment variables (recommended)
   - `config.json` - For JSON-based configurations
   - `config.yml` - For YAML-based configurations (Python, Ruby, etc.)
   - `config.js` - For Node.js frameworks

2. **Copy the template file**:
   ```bash
   # For .env (most common)
   cp env.template .env
   
   # OR for JSON
   cp config.json.template config.json
   
   # OR for YAML
   cp config.yml.template config.yml
   
   # OR for JavaScript
   cp config.js.template config.js
   ```

3. **Edit the configuration file** with your actual database credentials.

## Configuration Files

### `env.template` (Recommended)
Environment variables template file that works with most frameworks. Copy to `.env` and load at startup using a library like `dotenv` (Node.js) or `python-dotenv` (Python).

**Usage in Node.js:**
```javascript
require('dotenv').config();
const dbConfig = {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  // ... etc
};
```

**Usage in Python:**
```python
from dotenv import load_dotenv
import os

load_dotenv()
db_config = {
    'host': os.getenv('DB_HOST'),
    'port': int(os.getenv('DB_PORT', 3306)),
    # ... etc
}
```

### `config.json.template`
JSON configuration template for frameworks that prefer JSON. Copy to `config.json` and customize.

### `config.yml.template`
YAML configuration template for Python (Flask/FastAPI), Ruby, or other YAML-based frameworks. Copy to `config.yml` and customize.

### `config.js.template`
JavaScript/Node.js configuration template that reads from environment variables with fallbacks. Copy to `config.js` and customize.

## Database Connection Details

### Required Settings
- **DB_HOST**: MySQL server hostname (default: `localhost`)
- **DB_PORT**: MySQL server port (default: `3306`)
- **DB_NAME**: Database name (default: `minecraft_church`)
- **DB_USER**: Database username
- **DB_PASSWORD**: Database password

### Connection Pool Settings
- **DB_CONNECTION_LIMIT**: Maximum number of connections in pool (default: `10`)
- **DB_CONNECTION_TIMEOUT**: Connection timeout in milliseconds (default: `10000`)
- **DB_QUEUE_LIMIT**: Maximum queue length for waiting connections (default: `0` = unlimited)

### Security Settings
- **API_SECRET**: Shared secret for server-to-API authentication (generate with `openssl rand -base64 32`)
- **ADMIN_TOKEN**: Token for admin approval endpoint (generate separately with `openssl rand -base64 32`)

## Database Setup

Before configuring the API, ensure your MySQL database is set up:

1. **Create the database** (if not already created):
   ```sql
   CREATE DATABASE IF NOT EXISTS minecraft_church 
   CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. **Run the schema**:
   ```bash
   mysql -u your_username -p minecraft_church < ../database/schema.sql
   ```

3. **Verify tables**:
   ```sql
   USE minecraft_church;
   SHOW TABLES;
   ```

## Security Best Practices

1. **Never commit actual credentials**:
   - Add `.env`, `config.json`, `config.yml`, and `config.js` to `.gitignore`
   - Only commit the `.template` files

2. **Generate strong secrets**:
   ```bash
   # Generate API_SECRET
   openssl rand -base64 32
   
   # Generate ADMIN_TOKEN (separate from API_SECRET)
   openssl rand -base64 32
   ```

3. **Use environment-specific configurations**:
   - Development: Use local database with relaxed security
   - Staging: Use separate database with production-like settings
   - Production: Use strong passwords, SSL connections, and restricted database user permissions

4. **Database user permissions**:
   Create a dedicated database user with minimal required permissions:
   ```sql
   CREATE USER 'minecraft_api'@'localhost' IDENTIFIED BY 'strong_password_here';
   GRANT SELECT, INSERT, UPDATE, DELETE ON minecraft_church.* TO 'minecraft_api'@'localhost';
   FLUSH PRIVILEGES;
   ```

5. **SSL for remote connections**:
   If your database is on a remote server, enable SSL:
   - Set `DB_SSL=true` in `.env`
   - Provide SSL certificate paths: `DB_SSL_CA`, `DB_SSL_CERT`, `DB_SSL_KEY`

## Connection String Format

Some frameworks use connection strings. The format is:
```
mysql://username:password@host:port/database
```

Example:
```
mysql://minecraft_user:secure_password123@localhost:3306/minecraft_church
```

## Framework-Specific Examples

### Node.js with mysql2
```javascript
const mysql = require('mysql2/promise');
const config = require('./config.js'); // or load from .env

const pool = mysql.createPool({
  host: config.database.host,
  port: config.database.port,
  database: config.database.database,
  user: config.database.user,
  password: config.database.password,
  connectionLimit: config.database.connectionLimit,
  charset: config.database.charset
});
```

### Python with mysql-connector-python
```python
import mysql.connector
from dotenv import load_dotenv
import os

load_dotenv()

config = {
    'host': os.getenv('DB_HOST'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'database': os.getenv('DB_NAME'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'charset': 'utf8mb4',
    'collation': 'utf8mb4_unicode_ci'
}

connection = mysql.connector.connect(**config)
```

### PHP with PDO
```php
<?php
// Load from .env or config file
$host = getenv('DB_HOST') ?: 'localhost';
$port = getenv('DB_PORT') ?: '3306';
$dbname = getenv('DB_NAME') ?: 'minecraft_church';
$username = getenv('DB_USER');
$password = getenv('DB_PASSWORD');

$dsn = "mysql:host=$host;port=$port;dbname=$dbname;charset=utf8mb4";
$pdo = new PDO($dsn, $username, $password);
```

## Testing the Connection

After configuration, test your database connection:

### Node.js
```javascript
const mysql = require('mysql2/promise');
const config = require('./config.js');

async function testConnection() {
  try {
    const connection = await mysql.createConnection({
      host: config.database.host,
      port: config.database.port,
      database: config.database.database,
      user: config.database.user,
      password: config.database.password
    });
    console.log('Database connection successful!');
    await connection.end();
  } catch (error) {
    console.error('Database connection failed:', error.message);
  }
}

testConnection();
```

### Python
```python
import mysql.connector
from dotenv import load_dotenv
import os

load_dotenv()

try:
    conn = mysql.connector.connect(
        host=os.getenv('DB_HOST'),
        port=int(os.getenv('DB_PORT', 3306)),
        database=os.getenv('DB_NAME'),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD')
    )
    print('Database connection successful!')
    conn.close()
except mysql.connector.Error as err:
    print(f'Database connection failed: {err}')
```

## Troubleshooting

### Connection Refused
- Check if MySQL server is running: `mysqladmin -u root -p status`
- Verify host and port are correct
- Check firewall rules if connecting to remote database

### Access Denied
- Verify username and password are correct
- Check database user has proper permissions
- Ensure database user can connect from your IP address

### Unknown Database
- Verify database name is correct (should be `minecraft_church`)
- Run the schema setup: `mysql -u user -p minecraft_church < ../database/schema.sql`

### Character Set Issues
- Ensure database uses `utf8mb4` charset
- Verify connection charset is set to `utf8mb4`

## Next Steps

1. ✅ Configure database connection (this step)
2. ⏳ Implement API endpoints (see task 3)
3. ⏳ Set up Denizen scripts to interact with API
4. ⏳ Configure Wix form integration

## Support

For issues with database configuration, check:
- MySQL server logs
- Database connection pool logs
- API server startup logs

Ensure all required tables exist by running:
```sql
USE minecraft_church;
SHOW TABLES;
```

Expected tables:
- `verification_codes`
- `verification_requests`
- `access_grants`
- `known_players`
- `audit_log` (optional)
