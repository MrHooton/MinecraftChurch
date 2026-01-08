# Quick Start Guide - Get Your System Running

Follow these steps in order to get your verification system working.

## Step 1: Set Up Database

### Option A: Use Your Existing Apex Database (`apexMC2969109`)

1. Connect to Apex MySQL:
   - Go to: `https://mysql.apexhosting.gdn/`
   - Or use MySQL client with your credentials

2. Select database `apexMC2969109`

3. Run the schema:
   - Open `database/schema.sql` from your project
   - Copy all the SQL
   - Paste and execute it in the Apex MySQL interface

4. Verify tables were created:
   ```sql
   SHOW TABLES;
   ```
   You should see: `verification_codes`, `verification_requests`, `access_grants`, `known_players`, `audit_log`

### Option B: Create New Database (Recommended)

1. In Apex MySQL, create new database:
   ```sql
   CREATE DATABASE minecraft_church 
   CHARACTER SET utf8mb4 
   COLLATE utf8mb4_unicode_ci;
   ```

2. Select the new database and run `database/schema.sql`

3. Update `.env` to use `minecraft_church` instead of `apexMC2969109`

---

## Step 2: Configure API Server

### 2.1 Create `.env` File

Create `api/.env` file with your Apex MySQL credentials:

```env
# Database Configuration (Apex MySQL)
DB_HOST=mysql.apexhosting.gdn
DB_PORT=3306
DB_NAME=apexMC2969109
DB_USER=apexMC2969109
DB_PASSWORD=Igcx^0V&#HNb7FwHoONuUZ

# Database Connection Pool Settings
DB_CONNECTION_LIMIT=10
DB_CONNECTION_TIMEOUT=10000
DB_QUEUE_LIMIT=0
DB_TIMEZONE=UTC

# SSL Configuration (Apex may require SSL)
DB_SSL=true

# API Server Configuration
API_HOST=0.0.0.0
API_PORT=3000

# Security Settings (OPTIONAL - leave empty to disable)
API_SECRET=
ADMIN_TOKEN=

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

**Important:** Replace `WIX_FORM_URL` with your actual Wix form URL when you create it.

### 2.2 Install Dependencies

Open terminal in the `api` folder:

```bash
cd api
npm install
```

### 2.3 Test Database Connection

```bash
node test-connection.js
```

You should see: `✅ Database connection successful!`

If it fails:
- Check your credentials in `.env`
- Try `DB_SSL=false` if SSL is causing issues
- Verify database exists and schema is installed

### 2.4 Start API Server

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

**Keep this terminal open!** The server needs to keep running.

---

## Step 3: Expose API Server Publicly

Your Denizen scripts need to reach your API. Choose one method:

### Option A: ngrok (Easiest for Testing)

1. Download ngrok: https://ngrok.com/download
2. Install and run:
   ```bash
   ngrok http 3000
   ```
3. Copy the forwarding URL (e.g., `https://abc123.ngrok.io`)
4. **Save this URL** - you'll need it for Denizen config

### Option B: Port Forwarding (For Production)

1. Configure your router to forward port 3000 to your computer
2. Find your public IP: https://whatismyipaddress.com
3. Use: `http://your-public-ip:3000`

### Option C: Keep It Local (If Server is Same Machine)

If your Minecraft server and API are on the same computer:
- Use: `http://localhost:3000` or `http://127.0.0.1:3000`

---

## Step 4: Configure Denizen

### 4.1 Edit API Configuration

Open `plugins/Denizen/scripts/api_config.dsc` and update:

```yaml
api_config:
  type: data
  data:
    # Your public API URL (from Step 3)
    api_url: "https://abc123.ngrok.io"  # or your public URL
    
    # Leave as-is if not using secrets
    api_secret: "YOUR_API_SECRET"
    
    # Your Wix form URL (update when you create the form)
    wix_form_url: "https://your-form-url.wixsite.com/verification"
```

### 4.2 Reload Denizen

In your Minecraft server console or in-game:

```
/ex reload
```

Or restart your server.

---

## Step 5: Test the System

### 5.1 Test API Health

Open browser or use curl:
```
http://localhost:3000/health
```

Should return JSON with `"status": "ok"` and `"database": "connected"`

### 5.2 Test Code Generation (In-Game)

1. Join your Minecraft server
2. Find the Doorkeeper NPC
3. Right-click the NPC
4. Check your inventory - you should receive a book with a verification code

### 5.3 Test API Directly (Optional)

Test code generation via API:
```bash
curl -X POST http://localhost:3000/api/codes/generate \
  -H "Content-Type: application/json" \
  -d '{"child_name":"TestPlayer","child_uuid":"test-uuid"}'
```

Should return JSON with a code.

---

## Step 6: Create Wix Form (When Ready)

1. Create a Wix form with these fields:
   - `parent_name` (text, required)
   - `parent_email` (email, required)
   - `child_name` (text, required)
   - `code` (text, required)
   - `consent` (checkbox, required)
   - `church` (text, optional)
   - `adult_join` (checkbox, optional)
   - `adult_name` (text, required if adult_join checked)

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

3. Update `api_config.dsc` with your Wix form URL

---

## Step 7: Approve Requests

When a parent submits the form, approve it via API:

### Option A: Using Browser/curl

```bash
# Get pending requests
curl "http://localhost:3000/api/requests?status=pending"

# Approve request ID 1
curl -X POST "http://localhost:3000/api/requests/1/approve" \
  -H "Content-Type: application/json" \
  -d '{"approved_by":"YourName","notes":"Approved"}'
```

### Option B: Using GET Endpoint (Simpler)

```
http://localhost:3000/api/approve?id=1&token=&approved_by=YourName&notes=Approved
```

(Since you're not using tokens, leave `token=` empty)

---

## Troubleshooting

### API Won't Start
- Check if port 3000 is already in use
- Verify Node.js is installed: `node --version`
- Check `.env` file exists and has correct credentials

### Database Connection Fails
- Verify credentials in `.env`
- Try `DB_SSL=false` first
- Check if Apex MySQL allows connections from your IP
- Test with: `node test-connection.js`

### Denizen Can't Reach API
- Verify `api_url` in `api_config.dsc` is correct
- Check if API server is running
- Test API URL in browser: `http://your-url/health`
- Check Denizen logs for errors

### Code Generation Fails
- Check Denizen logs: `/ex debug`
- Verify API is accessible from server
- Test API directly with curl
- Check `api_config.dsc` has correct URL

### NPC Doesn't Work
- Verify NPC has `doorkeeper_assign` assignment
- Check Denizen scripts loaded: `/ex scripts`
- Reload scripts: `/ex reload`
- Check server logs for errors

---

## Next Steps (Future)

1. **Grant Poller Script** - Automatically apply LuckPerms when grants are approved
2. **Player Join Hook** - Register players when they join
3. **Admin Interface** - Web page for approving requests
4. **WorldGuard Setup** - Configure restricted areas
5. **LuckPerms Groups** - Set up guest, child, adult groups

---

## Quick Reference

### Important Files
- `api/.env` - Database and API configuration
- `plugins/Denizen/scripts/api_config.dsc` - Denizen API config
- `plugins/Denizen/scripts/doorkeeper.dsc` - NPC script

### Important URLs
- API Health: `http://localhost:3000/health`
- API Docs: See `api/API_DOCUMENTATION.md`

### Important Commands
- Start API: `cd api && npm start`
- Test DB: `cd api && node test-connection.js`
- Reload Denizen: `/ex reload`

---

## You're Ready!

Once you complete Steps 1-5, your basic system is working:
- ✅ Database connected
- ✅ API server running
- ✅ NPC generates codes
- ✅ Players get verification books

Then you can:
- Create the Wix form (Step 6)
- Test the full flow (submit form → approve → grant access)

Good luck! 🚀
