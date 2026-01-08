# Minecraft Church Verification System - Setup Guide

This guide will help you set up the local Node.js API server to connect to your Apex MySQL database and expose it publicly for Denizen to access.

## Prerequisites

- Node.js (v14 or higher)
- Access to Apex MySQL database credentials
- A way to expose your local server publicly (ngrok, port forwarding, or public IP)

## Step 1: Install Dependencies

Navigate to the `api` directory and install dependencies:

```bash
cd api
npm install
```

## Step 2: Configure Environment Variables

1. Copy the environment template:
   ```bash
   cp env.template .env
   ```

2. Edit `.env` with your actual values:
   ```env
   # Database Configuration (Apex MySQL)
   DB_HOST=your-apex-mysql-host
   DB_PORT=3306
   DB_NAME=minecraft_church
   DB_USER=your_database_username
   DB_PASSWORD=your_database_password

   # API Server Configuration
   API_HOST=0.0.0.0  # Listen on all interfaces
   API_PORT=3000

   # Security Settings
   # Generate with: openssl rand -base64 32
   API_SECRET=your_generated_secret_here_minimum_32_characters
   ADMIN_TOKEN=your_generated_admin_token_here

   # Verification Code Settings
   CODE_EXPIRATION_MINUTES=15
   CODE_LENGTH=6

   # Integration Settings
   WIX_FORM_URL=https://your-form-url.wixsite.com/verification
   ```

3. Generate secure secrets:
   ```bash
   # Generate API_SECRET
   openssl rand -base64 32

   # Generate ADMIN_TOKEN (different from API_SECRET)
   openssl rand -base64 32
   ```

## Step 3: Test Database Connection

Test your database connection:

```bash
node test-connection.js
```

If successful, you should see:
```
✅ Database connection successful!
```

## Step 4: Start the API Server

Start the server:

```bash
npm start
```

You should see:
```
✅ Database connection successful!
🚀 Minecraft Church Verification System API
📡 Server running on http://0.0.0.0:3000
🌍 Environment: development
📊 Health check: http://0.0.0.0:3000/health
```

## Step 5: Expose Your Server Publicly

You need to make your local server accessible from the internet so Denizen can call it. Choose one method:

### Option A: Using ngrok (Recommended for Testing)

1. Install ngrok: https://ngrok.com/download
2. Start ngrok:
   ```bash
   ngrok http 3000
   ```
3. Copy the forwarding URL (e.g., `https://abc123.ngrok.io`)
4. Use this URL in your Denizen configuration

### Option B: Port Forwarding (For Production)

1. Configure your router to forward port 3000 to your local machine
2. Find your public IP: https://whatismyipaddress.com
3. Use `http://your-public-ip:3000` in your Denizen configuration

### Option C: Cloud Deployment (For Production)

Deploy the API to a cloud service (Heroku, Railway, DigitalOcean, etc.) and use that URL.

## Step 6: Configure Denizen Scripts

1. Edit `plugins/Denizen/scripts/api_config.dsc`:
   ```yaml
   api_config:
     type: data
     data:
       # Your public API URL (from Step 5)
       api_url: "https://abc123.ngrok.io"  # or your public URL
       
       # Your API secret from .env (API_SECRET)
       api_secret: "your_api_secret_here"
       
       # Your Wix form URL
       wix_form_url: "https://your-form-url.wixsite.com/verification"
   ```

2. Reload Denizen scripts:
   ```
   /ex reload
   ```

## Step 7: Test the System

1. **Test API Health:**
   ```bash
   curl http://localhost:3000/health
   ```

2. **Test Code Generation (from server console or Denizen):**
   ```bash
   curl -X POST http://localhost:3000/api/codes/generate \
     -H "X-API-Secret: your_api_secret" \
     -H "Content-Type: application/json" \
     -d '{"child_name":"TestPlayer","child_uuid":"test-uuid"}'
   ```

3. **Test in-game:**
   - Join the server
   - Click the Doorkeeper NPC
   - Check your inventory for the verification code book

## Step 8: Configure Wix Form Integration

1. Create your Wix form with these fields:
   - `parent_name` (text, required)
   - `parent_email` (email, required)
   - `child_name` (text, required)
   - `code` (text, required)
   - `consent` (checkbox, required)
   - `church` (text, optional)
   - `adult_join` (checkbox, optional)
   - `adult_name` (text, required if adult_join is checked)

2. Set up Wix Automation:
   - Trigger: Form Submitted
   - Action: Send HTTP Request
   - Method: POST
   - URL: `https://your-api-url/api/requests/submit`
   - Headers: `Content-Type: application/json`
   - Body (JSON):
     ```json
     {
       "child_name": "{{form.child_name}}",
       "adult_name": "{{form.adult_name}}",
       "code": "{{form.code}}",
       "parent_name": "{{form.parent_name}}",
       "parent_email": "{{form.parent_email}}",
       "consent": {{form.consent}},
       "church": "{{form.church}}",
       "adult_join": {{form.adult_join}}
     }
     ```

## Step 9: Set Up Admin Approval

You can approve requests via:

1. **API Endpoint** (requires admin token):
   ```bash
   curl -X POST http://localhost:3000/api/requests/1/approve \
     -H "X-Admin-Token: your_admin_token" \
     -H "Content-Type: application/json" \
     -d '{"approved_by":"AdminName","notes":"Approved"}'
   ```

2. **Or create a simple admin page** (future enhancement)

## Troubleshooting

### Database Connection Fails
- Verify your Apex MySQL credentials
- Check if your IP is whitelisted in Apex MySQL
- Test connection with: `node test-connection.js`

### API Not Accessible from Internet
- Check firewall settings
- Verify port forwarding (if using)
- Test with: `curl http://your-public-url/health`

### Denizen Can't Reach API
- Verify `api_url` in `api_config.dsc` is correct
- Check `api_secret` matches your `.env` file
- Check Denizen logs for HTTP errors

### Code Generation Fails
- Check Denizen logs for error messages
- Verify API server is running
- Test API directly with curl (see Step 7)

## Security Notes

1. **Never commit `.env` file** - It contains sensitive credentials
2. **Use HTTPS in production** - Set up SSL/TLS for your API
3. **Restrict CORS** - Set `CORS_ORIGIN` in `.env` to your Wix domain
4. **Keep secrets secure** - Rotate secrets periodically
5. **Monitor logs** - Check for suspicious activity

## Next Steps

1. Set up Denizen polling script for grants (see grant_poller.dsc)
2. Set up player join hook (see player_seen.dsc)
3. Configure WorldGuard regions for restricted access
4. Set up LuckPerms groups (guest, child, adult, etc.)

## Support

For issues:
- Check server logs: `logs/latest.log`
- Check API logs: Console output or `api.log` (if configured)
- Check Denizen debug: `/ex debug` in-game
