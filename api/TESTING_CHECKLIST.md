# Testing Checklist

Your API server is running! Now let's test everything works.

## ✅ Server Status

- [x] Database connected
- [x] API server running on http://0.0.0.0:3000
- [x] Public IP: 136.111.209.208:3000

## Step 1: Test API Endpoints

### Test Health Check
Open browser or use curl:
```
http://136.111.209.208:3000/health
```
Or locally:
```
http://localhost:3000/health
```

Should return JSON with `"status": "ok"` and `"database": "connected"`

### Test Code Generation (Optional)
```bash
curl -X POST http://localhost:3000/api/codes/generate \
  -H "Content-Type: application/json" \
  -d "{\"child_name\":\"TestPlayer\",\"child_uuid\":\"test-uuid\"}"
```

Should return JSON with a 6-character code.

## Step 2: Configure Denizen

### Update Denizen Config
File: `plugins/Denizen/scripts/api_config.dsc`

Should already be set to:
```yaml
api_url: "http://136.111.209.208:3000"
```

### Reload Denizen
In Minecraft server console or in-game:
```
/ex reload
```

## Step 3: Test In-Game NPC

1. **Join your Minecraft server**
2. **Find the Doorkeeper NPC** (in the lobby/church area)
3. **Right-click the NPC**
4. **Check your inventory** - you should receive a written book with:
   - Your player name
   - A 6-character verification code
   - Instructions and Wix form URL

## Step 4: Check Logs

### API Server Logs
Check the terminal where `npm start` is running. Should show:
- Connection successful messages
- Any API requests when NPC is clicked

### Denizen Logs
Check server logs for:
- Doorkeeper script execution
- API calls
- Any errors

### Test Public Access (Optional)
From another device or browser:
```
http://136.111.209.208:3000/health
```

If you can access it, the public IP is working!

## Step 5: Verify Database

Check your database to see if code was created:

In phpMyAdmin or MySQL:
```sql
SELECT * FROM verification_codes ORDER BY created_at DESC LIMIT 5;
```

After clicking NPC, you should see a new code entry.

## Step 6: Next Steps

Once NPC is working:

1. **Create Wix Form** (when ready)
   - Set up form fields
   - Configure webhook to: `http://136.111.209.208:3000/api/requests/submit`

2. **Test Form Submission**
   - Submit form with a generated code
   - Check `verification_requests` table in database

3. **Approve Requests**
   - Use API endpoint to approve
   - Or create admin interface

4. **Set Up Grant Poller** (next step)
   - Denizen script to poll for approved grants
   - Apply LuckPerms commands automatically

## Troubleshooting

### NPC Doesn't Generate Code
- Check Denizen logs: `/ex debug`
- Verify `api_config.dsc` has correct URL
- Test API directly: `http://localhost:3000/health`
- Check if NPC has `doorkeeper_assign` assignment

### API Not Accessible from Server
- Check firewall allows port 3000
- Verify public IP is correct
- Test: `http://136.111.209.208:3000/health` from browser

### Database Errors
- Verify database connection: `node test-connection.js`
- Check tables exist: `SHOW TABLES;` in MySQL

## Quick Test Commands

```bash
# Test API locally
curl http://localhost:3000/health

# Test API publicly (from another device)
curl http://136.111.209.208:3000/health

# Test code generation
curl -X POST http://localhost:3000/api/codes/generate \
  -H "Content-Type: application/json" \
  -d '{"child_name":"TestPlayer"}'
```

## Success Indicators

✅ API server shows "Database connection successful!"  
✅ Health endpoint returns JSON  
✅ NPC click gives you a book with code  
✅ Database shows new code entry  
✅ No errors in server logs  

---

**You're ready to test! Join the server and click the Doorkeeper NPC!** 🎮
