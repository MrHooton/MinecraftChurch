# Public Access Troubleshooting

Can't access `136.111.209.208:3000`? Let's fix it step by step.

## Quick Checks

### 1. Test Locally First
Make sure it works locally:
```
http://localhost:3000/health
```

If this doesn't work, the server might not be running correctly.

### 2. Check Server is Actually Running
In your terminal where you ran `npm start`, you should see:
```
🚀 Minecraft Church Verification System API
📡 Server running on http://0.0.0.0:3000
```

If you don't see this, the server might have crashed.

### 3. Use http:// Prefix
Make sure you're using the full URL:
```
http://136.111.209.208:3000/health
```
Not just: `136.111.209.208:3000`

## Common Issues

### Issue 1: Windows Firewall Blocking

**Solution: Allow port 3000**

#### Method A: PowerShell (Run as Administrator)
```powershell
New-NetFirewallRule -DisplayName "Minecraft Church API" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

#### Method B: Windows Firewall GUI
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" and enter port `3000`
6. Select "Allow the connection"
7. Apply to all profiles
8. Name it: "Minecraft Church API Server"

### Issue 2: Router Port Forwarding Needed

If your computer is behind a router, you need to forward port 3000.

1. **Find your router's admin IP** (usually `192.168.1.1` or `192.168.0.1`)
2. **Log into router admin panel**
3. **Find "Port Forwarding" or "Virtual Server"**
4. **Add rule:**
   - External Port: `3000`
   - Internal Port: `3000`
   - Protocol: `TCP`
   - Internal IP: Your computer's local IP (find with `ipconfig` in cmd)
   - Save

5. **Find your local IP:**
   ```bash
   ipconfig
   ```
   Look for "IPv4 Address" - something like `192.168.1.100`

### Issue 3: ISP Blocking Ports

Some ISPs block incoming connections on non-standard ports.

**Test with a different port:**
1. Change `API_PORT=3001` in `.env`
2. Update router port forwarding to 3001
3. Restart server
4. Try: `http://136.111.209.208:3001/health`

### Issue 4: Server Only Listening on Localhost

**Verify server config:**
Check your `.env` has:
```env
API_HOST=0.0.0.0
API_PORT=3000
```

NOT:
```env
API_HOST=localhost  # This won't work for public access!
```

### Issue 5: Public IP Changed

Your public IP might have changed. Check your current IP:
- Visit: https://whatismyipaddress.com/
- Compare with `136.111.209.208`

## Step-by-Step Diagnostic

### Step 1: Test Local Access
```bash
curl http://localhost:3000/health
```
or open in browser: `http://localhost:3000/health`

✅ If this works, server is running correctly.

### Step 2: Test from Same Network
From another device on same WiFi network:
```
http://192.168.1.X:3000/health
```
(Replace X with your computer's local IP from `ipconfig`)

✅ If this works, server is listening correctly.
❌ If this fails, check Windows Firewall.

### Step 3: Test Public Access
From another network (phone using mobile data, or different location):
```
http://136.111.209.208:3000/health
```

✅ If this works, everything is configured correctly!
❌ If this fails, you need router port forwarding.

## Alternative: Use Localhost for Testing

If public access is too complicated, you can test locally first:

1. **Update Denizen config** to use localhost:
   ```yaml
   api_url: "http://localhost:3000"
   ```

2. **Only works if Minecraft server and API are on same computer**

3. **For production**, you'll need public access working.

## Test Commands

```bash
# Test local
curl http://localhost:3000/health

# Test from another device on same network
curl http://192.168.1.100:3000/health  # Use your local IP

# Test public (from different network)
curl http://136.111.209.208:3000/health
```

## Quick Fix: Check These First

1. ✅ Server running? Check terminal output
2. ✅ Firewall allows port 3000? Run PowerShell command above
3. ✅ Using `http://` prefix? Not just the IP
4. ✅ Router port forwarding? If behind router
5. ✅ Correct IP? Check https://whatismyipaddress.com/

## If Still Not Working

Share:
1. Can you access `http://localhost:3000/health`? (Yes/No)
2. Are you behind a router? (Yes/No)
3. What error do you see? (Connection refused, timeout, etc.)
4. Is server terminal showing it's running?
