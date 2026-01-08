# Database Connection Troubleshooting

## Quick Fix: Try Without SSL First

Edit `api/.env` and change:
```env
DB_SSL=false
```

Then test again:
```bash
node test-connection.js
```

## Common Issues

### 1. SSL Configuration Error
**Symptom:** Connection fails with SSL-related error

**Solution:**
- Try `DB_SSL=false` first
- If that works, Apex MySQL might not require SSL
- If you need SSL, you may need proper certificates (contact Apex support)

### 2. Password Special Characters
**Symptom:** Authentication fails even with correct password

**Solution:**
- Your password contains special characters: `Igcx^0V&#HNb7FwHoONuUZ`
- Make sure the password in `.env` is exactly as shown (no quotes needed)
- If using quotes, they must be outside the value: `DB_PASSWORD="Igcx^0V&#HNb7FwHoONuUZ"`

### 3. Database Doesn't Exist
**Symptom:** Error code `ER_BAD_DB_ERROR` or `1049`

**Solution:**
- Create the database first in Apex MySQL panel
- Or use existing database: `apexMC2969109`
- Verify database name in `.env` matches exactly

### 4. Host/Port Issues
**Symptom:** `ECONNREFUSED` or `ETIMEDOUT`

**Solution:**
- Verify host: `mysql.apexhosting.gdn`
- Verify port: `3306`
- Check if your IP is whitelisted in Apex MySQL panel
- Try connecting with MySQL client to verify credentials work

### 5. Firewall/Network Issues
**Symptom:** Connection times out

**Solution:**
- Check if your IP is whitelisted in Apex control panel
- Verify firewall allows outbound connections to port 3306
- Try from different network to rule out local firewall

## Step-by-Step Debugging

1. **Test with MySQL client first** (if available):
   ```bash
   mysql -h mysql.apexhosting.gdn -P 3306 -u apexMC2969109 -p apexMC2969109
   ```
   Enter password: `Igcx^0V&#HNb7FwHoONuUZ`
   
   If this works, the issue is in Node.js config, not credentials.

2. **Test with SSL disabled**:
   ```env
   DB_SSL=false
   ```

3. **Test with minimal config** - temporarily modify `test-connection.js`:
   ```javascript
   const connection = await mysql.createConnection({
     host: 'mysql.apexhosting.gdn',
     port: 3306,
     database: 'apexMC2969109',
     user: 'apexMC2969109',
     password: 'Igcx^0V&#HNb7FwHoONuUZ',
     ssl: false  // Try without SSL
   });
   ```

4. **Check Apex MySQL Panel**:
   - Log into Apex control panel
   - Verify database exists
   - Check if your IP is whitelisted
   - Verify user permissions

5. **Check for IP Whitelisting**:
   - Apex MySQL might require IP whitelisting
   - Add your current IP to allowed IPs in Apex panel
   - Your IP: Check at https://whatismyipaddress.com

## Get More Error Details

The improved `test-connection.js` now shows:
- Error code
- Error message  
- Error number
- Full error details

Run it and share the full output for help.
