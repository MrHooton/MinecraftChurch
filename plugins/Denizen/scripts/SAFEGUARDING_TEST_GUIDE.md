# Two-Person Safeguarding - Testing Guide

## 🎯 Quick Test (5 minutes)

This guide helps you verify the two-person safeguarding system is working correctly.

---

## Prerequisites

### 1. Test Accounts
You'll need **3 test accounts** or players:
- **Account 1:** Director role (`/lp user TestDirector parent set director`)
- **Account 2:** Observer role (`/lp user TestObserver parent set observer`)
- **Account 3:** Child role (`/lp user TestChild parent set child`)

### 2. Test Region
We'll use `room7` in `Minecraft_Church` world.

**Verify region exists:**
```
/rg info room7
```

Should show:
- Members: g:child, g:director, g:observer
- Flags: entry: deny

---

## Test Suite

### ✅ Test 1: Block Child Entry (No Supervision)

**Objective:** Verify child cannot enter alone.

**Steps:**
1. Log in as **TestChild**
2. Navigate to `room7` entrance
3. Try to enter the region

**Expected Result:**
```
⚠ SAFEGUARDING: Two adults required for supervision.
This area requires at least 2 supervising adults (director/observer) when children are present.
Currently in region: 0 supervisor(s), 1 child(ren).
```
- ✅ Child should be **teleported to spawn**
- ✅ Admins should see: `[SAFEGUARD] TestChild blocked from room7: insufficient supervision (0/2 adults)`

**If this doesn't happen:** Check Denizen console for errors, verify script is loaded (`/ex reload`)

---

### ✅ Test 2: Block Child Entry (Only 1 Adult)

**Objective:** Verify child cannot enter with only 1 adult.

**Steps:**
1. Have **TestDirector** enter `room7`
2. Log in as **TestChild**
3. Try to enter `room7`

**Expected Result:**
```
⚠ SAFEGUARDING: Two adults required for supervision.
This area requires at least 2 supervising adults (director/observer) when children are present.
Currently in region: 1 supervisor(s), 1 child(ren).
```
- ✅ Child should be **blocked and teleported to spawn**
- ✅ Admin notification should show: `(1/2 adults)`

---

### ✅ Test 3: Allow Child Entry (2 Adults Present)

**Objective:** Verify child CAN enter with adequate supervision.

**Steps:**
1. Have **TestDirector** enter `room7`
2. Have **TestObserver** enter `room7`
3. Now have **TestChild** enter `room7`

**Expected Result:**
```
✓ Entering supervised area (2 adult supervisors present)
```
- ✅ Child should be **allowed to enter**
- ✅ Child should remain in region
- ✅ No teleportation should occur

**Verify with:**
```
/safeguard status room7
```

Should show:
```
Supervisors: 2 (minimum: 2)
  - TestDirector (director)
  - TestObserver (observer)
Children: 1
  - TestChild

✓ COMPLIANT: Adequate supervision
```

---

### ✅ Test 4: Eject Child When Supervisor Leaves

**Objective:** Verify child is ejected if supervision drops.

**Setup:**
1. **TestDirector**, **TestObserver**, and **TestChild** are all in `room7`

**Steps:**
1. Have **TestObserver** leave `room7` (walk out)

**Expected Result:**
- ✅ **TestChild** should be **immediately ejected to spawn**
- ✅ TestChild sees message:
```
⚠ SAFEGUARDING: Adult supervisor left. You are being returned to spawn for safety.
```
- ✅ Admins see:
```
[SAFEGUARD] Supervision dropped in room7. Ejected 1 child(ren) (only 1/2 adults remain)
```

---

### ✅ Test 5: Eject Child When Supervisor Quits

**Objective:** Verify child is ejected if supervisor disconnects.

**Setup:**
1. **TestDirector**, **TestObserver**, and **TestChild** are all in `room7`

**Steps:**
1. Have **TestObserver** quit/disconnect from the server

**Expected Result:**
- ✅ **TestChild** should be **immediately ejected to spawn**
- ✅ TestChild sees message:
```
⚠ SAFEGUARDING: Adult supervisor disconnected. You are being returned to spawn for safety.
```
- ✅ Admins see:
```
[SAFEGUARD] TestObserver quit from room7. Ejected 1 child(ren) (only 1/2 adults remain)
```

---

### ✅ Test 6: Multiple Children

**Objective:** Verify system works with multiple children.

**Setup:**
1. Have **TestDirector** and **TestObserver** in `room7`
2. Have **TestChild1** enter `room7` (should succeed)
3. Have **TestChild2** enter `room7` (should also succeed)

**Steps:**
1. Have **TestDirector** leave `room7`

**Expected Result:**
- ✅ **BOTH children** should be ejected
- ✅ Both see safeguarding message
- ✅ Admin notification shows: `Ejected 2 child(ren)`

---

### ✅ Test 7: Admin Status Command

**Objective:** Verify monitoring command works.

**Steps:**
1. Set up: 2 adults + 1 child in `room7`
2. Run as admin:
```
/safeguard status room7
```

**Expected Result:**
```
━━━ Safeguarding Status: room7 ━━━
World: Minecraft_Church
Minimum adults required: 2

Current supervision:
  Supervisors: 2 (minimum: 2)
    - TestDirector (director)
    - TestObserver (observer)
  Children: 1
    - TestChild

✓ COMPLIANT: Adequate supervision
```

---

### ✅ Test 8: List Protected Regions

**Objective:** Verify list command works.

**Steps:**
1. Run as admin:
```
/safeguard list
```

**Expected Result:**
```
━━━ Protected Regions (Two-Person Rule) ━━━
- Minecraft_Church:room7
- sd:sd
- sd:sd2
Total: 3 region(s)
```

---

## 📊 Audit Log Verification

After running tests, verify events are logged to database:

```sql
SELECT 
  action_type,
  target_player,
  details,
  created_at
FROM audit_log 
WHERE action_type LIKE 'safeguard_%' 
ORDER BY created_at DESC 
LIMIT 20;
```

**Expected event types:**
- `safeguard_entry_blocked` - When children were blocked
- `safeguard_entry_allowed` - When children were allowed in
- `safeguard_supervision_dropped` - When supervisor left
- `safeguard_supervisor_quit` - When supervisor disconnected

---

## 🐛 Troubleshooting

### Child not being blocked

**Check:**
1. Is child in `child` group? `/lp user TestChild info`
2. Is region in protected regions list? Check `two_person_safeguard.dsc`
3. Is script loaded? `/ex reload` then retry
4. Check console for Denizen errors

### Child not being ejected when supervisor leaves

**Check:**
1. Region name is correct (case-sensitive)
2. Script is monitoring exit events (check console)
3. Try manual eject test: Have supervisor walk out slowly

### No admin notifications

**Check:**
1. Are you OP? `/op YourName`
2. Check if `announce to_ops` is working: `/ex announce "test" to_ops`

### No audit logs in database

**Check:**
1. Database connection working? (Other Denizen scripts working?)
2. `audit_logging: true` in config?
3. Check MySQL user has INSERT permission on audit_log table

---

## ✅ Success Criteria

Your system is working correctly if:

- [x] **Test 1:** Child blocked when entering alone
- [x] **Test 2:** Child blocked with only 1 adult
- [x] **Test 3:** Child allowed with 2+ adults
- [x] **Test 4:** Child ejected when supervisor leaves
- [x] **Test 5:** Child ejected when supervisor quits
- [x] **Test 6:** Multiple children ejected together
- [x] **Test 7:** Status command shows accurate info
- [x] **Test 8:** List command shows protected regions
- [x] **Audit logs** recorded in database

**Once all tests pass, your two-person safeguarding system is fully operational!** ✅

---

## 📝 Test Results Template

Copy this to document your testing:

```
## Two-Person Safeguarding Test Results
Date: _______________
Tester: _______________

[ ] Test 1: Block child alone - PASS / FAIL
[ ] Test 2: Block child with 1 adult - PASS / FAIL
[ ] Test 3: Allow child with 2 adults - PASS / FAIL
[ ] Test 4: Eject when supervisor leaves - PASS / FAIL
[ ] Test 5: Eject when supervisor quits - PASS / FAIL
[ ] Test 6: Multiple children ejected - PASS / FAIL
[ ] Test 7: Status command works - PASS / FAIL
[ ] Test 8: List command works - PASS / FAIL
[ ] Audit logs recorded - PASS / FAIL

Overall Status: PASS / FAIL

Notes:
_________________________________
_________________________________
_________________________________
```

---

## 🔄 Regular Testing Schedule

**Recommended:**
- Run full test suite after any server updates
- Run Test 3-5 monthly to verify system still works
- Review audit logs weekly for any anomalies
- Test with new staff to verify their understanding

---

## 🚨 Emergency Procedures

**If safeguarding system fails:**
1. **Immediately notify all staff**
2. **Do not allow children in spiritual direction spaces** until system is verified
3. **Check Denizen console** for errors
4. **Reload script:** `/ex reload`
5. **Verify with Test 1-3** before resuming normal operations
6. **Document the incident** in audit logs

**Contact:** Server administrator if system cannot be restored immediately.
