# Public IP Setup Guide

Your API server will be accessible at: `http://136.111.209.208:3000`

## Step 1: Configure Firewall

### Windows Firewall
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" and enter port `3000`
6. Select "Allow the connection"
7. Apply to all profiles
8. Name it: "Minecraft Church API Server"

Or via PowerShell (Run as Admin):
```powershell
New-NetFirewallRule -DisplayName "Minecraft Church API" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### Router Port Forwarding (If Behind Router)

If your computer is behind a router, you may need to forward port 3000:

1. Log into your router admin panel (usually `192.168.1.1` or `192.168.0.1`)
2. Find "Port Forwarding" or "Virtual Server" settings
3. Add rule:
   - External Port: `3000`
   - Internal Port: `3000`
   - Protocol: `TCP`
   - Internal IP: Your computer's local IP (find with `ipconfig` in cmd)
   - Save

## Step 2: Start API Server

Your `.env` already has `API_HOST=0.0.0.0` which is correct - this makes it listen on all network interfaces.

Start the server:
```bash
cd api
npm start
```

You should see:
```
🚀 Minecraft Church Verification System API
📡 Server running on http://0.0.0.0:3000
```

## Step 3: Test Public Access

### From Your Computer:
```bash
curl http://localhost:3000/health
```

### From Another Device/Network:
Open browser or use curl:
```
http://136.111.209.208:3000/health
```

Should return:
```json
{
  "status": "ok",
  "timestamp": "...",
  "database": "connected",
  "version": "1.0.0"
}
```

## Step 4: Update Denizen Configuration

Update `plugins/Denizen/scripts/api_config.dsc`:

```yaml
api_config:
  type: data
  data:
    # Your public API URL
    api_url: "http://136.111.209.208:3000"
    
    # Leave as-is if not using secrets
    api_secret: "YOUR_API_SECRET"
    
    # Your Wix form URL
    wix_form_url: "https://your-form-url.wixsite.com/verification"
```

Then reload Denizen:
```
/ex reload
```

## Step 5: Security Considerations

⚠️ **Important Security Notes:**

1. **No Authentication**: Since you disabled API secrets, anyone can access your API endpoints
   - Consider using a firewall to only allow your Minecraft server IP
   - Or re-enable API_SECRET in production

2. **HTTPS**: For production, consider:
   - Using a reverse proxy (nginx) with SSL certificate
   - Or deploying to a cloud service with built-in SSL

3. **Firewall Rules**: Restrict access if possible:
   - Only allow connections from your Minecraft server's IP
   - Or restrict to specific IP ranges

## Troubleshooting

### Cannot Access from Internet

1. **Check Firewall**: Make sure Windows Firewall allows port 3000
2. **Check Router**: Port forwarding may be needed if behind router
3. **Check ISP**: Some ISPs block incoming connections (try different port)
4. **Check IP**: Your public IP might change if you don't have static IP

### Connection Refused

- Verify server is running: `npm start`
- Check server logs for errors
- Try accessing from same computer: `http://localhost:3000/health`

### Works Locally But Not Publicly

- Router port forwarding needed
- ISP may be blocking ports
- Firewall on router may need configuration

## Your API Endpoints

Once running, these will be accessible:

- Health: `http://136.111.209.208:3000/health`
- Generate Code: `POST http://136.111.209.208:3000/api/codes/generate`
- Submit Request: `POST http://136.111.209.208:3000/api/requests/submit`
- Approve: `GET http://136.111.209.208:3000/api/approve?id=1&approved_by=YourName`
- Get Grants: `GET http://136.111.209.208:3000/api/grants`

## Quick Test

Test from command line (on another computer or your phone's browser):
```bash
curl http://136.111.209.208:3000/health
```

If you get a JSON response, it's working! 🎉
