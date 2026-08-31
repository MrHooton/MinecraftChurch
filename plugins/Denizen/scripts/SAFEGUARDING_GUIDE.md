# Two-Person Safeguarding System

## Overview

This system enforces a **strict two-person rule** in spiritual direction and private spaces to ensure child safety. No child can be alone with a single adult.

## ⚙️ How It Works

### Automatic Protection

The safeguarding system **automatically**:

1. **Monitors region entry** - Blocks children from entering if insufficient adult supervision
2. **Monitors region exit** - Ejects children if an adult supervisor leaves
3. **Monitors disconnections** - Ejects children if a supervisor quits/crashes
4. **Logs all events** - Creates audit trail in database for compliance

### The Rules

**Minimum Supervision Required:**
- **2 supervising adults** (director + observer, or 2 directors, etc.) must be present
- Before ANY child can enter a protected region
- Throughout the entire time children are present

**What Happens If Rules Are Violated:**
- ❌ **Child tries to enter with < 2 adults** → Entry blocked, teleported to spawn
- ❌ **Supervisor leaves, dropping below 2 adults** → All children ejected to spawn
- ❌ **Supervisor disconnects** → All children ejected to spawn

### Protected Regions

By default, these regions require two-person supervision:
- `Minecraft_Church:room7` - Spiritual direction room
- `sd:sd` - Spiritual direction world (main area)
- `sd:sd2` - Spiritual direction world (secondary area)

## 🎯 Role Definitions

### Supervising Adults
These groups count as supervising adults:
- **director** - Vetted spiritual directors
- **observer** - Trained observers

**Note:** `adult` group does NOT count as supervising adult for spiritual direction spaces. Only vetted roles (director/observer) provide supervision.

### Children Requiring Supervision
These groups require two-person supervision:
- **child** - Verified children

## 📋 Admin Commands

### `/safeguard list`
**Permission:** `minecraftchurch.admin`

Lists all regions protected by two-person rule.

**Example:**
```
/safeguard list
```

**Output:**
```
━━━ Protected Regions (Two-Person Rule) ━━━
- Minecraft_Church:room7
- sd:sd
- sd:sd2
Total: 3 region(s)
```

---

### `/safeguard status <region>`
**Permission:** `minecraftchurch.admin`

Check current supervision status in a specific region.

**Example:**
```
/safeguard status room7
```

**Output:**
```
━━━ Safeguarding Status: room7 ━━━
World: Minecraft_Church
Minimum adults required: 2

Current supervision:
  Supervisors: 2 (minimum: 2)
    - DirectorName (director)
    - ObserverName (observer)
  Children: 1
    - ChildName

✓ COMPLIANT: Adequate supervision
```

---

## 🧪 Testing Scenarios

### Test 1: Block Child Entry (Insufficient Supervision)

**Setup:**
1. Have 0 or 1 adult in `room7`
2. Try to enter as child

**Expected Result:**
- ❌ Child blocked from entry
- Message: "⚠ SAFEGUARDING: Two adults required for supervision."
- Child teleported to spawn
- Admin notification sent

---

### Test 2: Allow Child Entry (Adequate Supervision)

**Setup:**
1. Have 2+ adults (director + observer) in `room7`
2. Enter as child

**Expected Result:**
- ✅ Child allowed to enter
- Message: "✓ Entering supervised area (2 adult supervisors present)"

---

### Test 3: Eject on Supervisor Leave

**Setup:**
1. Have 2 adults + 1 child in `room7`
2. One adult leaves region

**Expected Result:**
- ❌ Child ejected to spawn
- Message: "⚠ SAFEGUARDING: Adult supervisor left. You are being returned to spawn for safety."
- Admin notification sent

---

### Test 4: Eject on Supervisor Disconnect

**Setup:**
1. Have 2 adults + 1 child in `room7`
2. One adult disconnects/quits

**Expected Result:**
- ❌ Child ejected to spawn
- Message: "⚠ SAFEGUARDING: Adult supervisor disconnected. You are being returned to spawn for safety."
- Admin notification sent

---

## 🔧 Configuration

### Adding Protected Regions

Edit `plugins/Denizen/scripts/two_person_safeguard.dsc`:

```yaml
two_person_config:
  type: data
  regions:
    - Minecraft_Church:room7
    - sd:sd
    - sd:sd2
    - YourWorld:YourRegion  # Add new regions here
```

**Format:** `WorldName:RegionName`

---

### Changing Minimum Adults Required

Edit `two_person_safeguard.dsc`:

```yaml
two_person_config:
  type: data
  min_adults: 2  # Change this number (default: 2)
```

---

### Adding Supervising Roles

Edit `two_person_safeguard.dsc`:

```yaml
two_person_config:
  type: data
  supervisor_groups:
    - director
    - observer
    - your_new_role  # Add new roles here
```

---

### Disabling Audit Logging

Edit `two_person_safeguard.dsc`:

```yaml
two_person_config:
  type: data
  audit_logging: false  # Change to false to disable
```

---

## 📊 Audit Trail

All safeguarding events are logged to the `audit_log` database table:

### Event Types Logged:
- `safeguard_entry_blocked` - Child blocked from entering
- `safeguard_entry_allowed` - Child allowed to enter with supervision
- `safeguard_supervision_dropped` - Supervisor left, children ejected
- `safeguard_supervisor_quit` - Supervisor disconnected, children ejected

### Example Query:
```sql
SELECT * FROM audit_log 
WHERE action_type LIKE 'safeguard_%' 
ORDER BY created_at DESC 
LIMIT 50;
```

### Audit Log Fields:
- `action_type` - Type of safeguarding event
- `target_player` - Player involved
- `details` - JSON with region, world, supervisor count, children count
- `created_at` - Timestamp of event

---

## 🚨 Important Safety Notes

### What This System Does:
- ✅ Prevents children from entering with insufficient supervision
- ✅ Ejects children if supervision drops
- ✅ Creates audit trail for compliance
- ✅ Notifies admins of all safeguarding events

### What This System Does NOT Do:
- ❌ Does NOT monitor voice chat (requires separate LiveKit configuration)
- ❌ Does NOT monitor private messages (already blocked for children via LuckPerms)
- ❌ Does NOT prevent adults from being alone together (only protects children)

### Additional Safeguarding Measures:
1. **Private messaging** - Disabled for children via LuckPerms (already configured)
2. **Voice chat** - Configure LiveKit plugin for monitoring/recording
3. **Screen recording** - Consider requiring observers to record sessions
4. **Session logs** - Use audit_log table for compliance reporting

---

## 🔍 Troubleshooting

### Problem: Children not being ejected when supervisor leaves

**Solution:**
1. Check region is in protected regions list
2. Verify region name matches exactly (case-sensitive)
3. Check server console for errors
4. Test with `/safeguard status <region>`

---

### Problem: Adults being blocked from entering

**Check:**
1. Is their group in `supervisor_groups` list?
2. Run `/lp user <name> info` to verify their group
3. Make sure they're not in `child` group

---

### Problem: System not working at all

**Checklist:**
1. ✅ Script file exists: `plugins/Denizen/scripts/two_person_safeguard.dsc`
2. ✅ Denizen loaded the script: `/ex reload`
3. ✅ Regions exist in WorldGuard: `/rg list`
4. ✅ Database connection works (check other Denizen scripts)
5. ✅ Check console for error messages

---

## 📞 Support

If you encounter issues:
1. Check server console for error messages
2. Review audit logs: `SELECT * FROM audit_log WHERE action_type LIKE 'safeguard_%'`
3. Test with `/safeguard status <region>` to see current state
4. Verify player groups with `/lp user <name> info`

---

## ✅ Compliance Checklist

Use this to verify proper implementation:

- [ ] Script installed: `two_person_safeguard.dsc`
- [ ] Protected regions configured (minimum: room7, sd, sd2)
- [ ] Supervisor groups configured (director, observer)
- [ ] Child group configured (child)
- [ ] Minimum adults set to 2
- [ ] Audit logging enabled
- [ ] Tested: Child blocked with < 2 adults
- [ ] Tested: Child allowed with 2+ adults
- [ ] Tested: Child ejected when supervisor leaves
- [ ] Tested: `/safeguard status` command works
- [ ] Database audit_log table receiving events
- [ ] Admin notifications working

**Status:** Once all boxes are checked, two-person safeguarding is fully operational.
