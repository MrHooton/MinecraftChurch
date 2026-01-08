# .env File Setup Reminder

## Your Database Credentials

Make sure your `api/.env` file has these settings:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=minecraft
DB_USER=minecraft_api
DB_PASSWORD=000000

# Database Connection Pool Settings
DB_CONNECTION_LIMIT=10
DB_CONNECTION_TIMEOUT=10000
DB_QUEUE_LIMIT=0
DB_TIMEZONE=UTC

# SSL Configuration (not needed for localhost)
DB_SSL=false

# API Server Configuration
API_HOST=0.0.0.0
API_PORT=3000

# Verification Code Settings
CODE_EXPIRATION_MINUTES=15
CODE_LENGTH=6

# Polling Settings
GRANT_POLL_INTERVAL=30

# Integration Settings
WIX_FORM_URL=https://your-form-url.wixsite.com/verification

# Environment
NODE_ENV=development
```

## Quick Check

Test your connection:
```bash
cd api
node test-connection.js
```

Should show:
- ✅ Database connection successful!
- ✅ Found 5 table(s) in database
