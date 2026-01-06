# Database Schema Review Guide

## What You're Looking At

This database schema is the foundation for the Minecraft Church verification system. It stores all information needed to safely verify children, approve access requests, and track who has joined the server.

## In Simple Terms

Think of the database as a secure filing cabinet with 5 drawers (tables). Each drawer stores different types of information that work together to ensure child safety and proper access control.

---

## 📋 Table-by-Table Explanation

### 1. `verification_codes` - The Code Generator
**What it does:** Stores temporary codes that the Doorkeeper NPC gives to children in the game.

**Real-world analogy:** Like a one-time-use coupon code that expires in 15 minutes.

**Key Information Stored:**
- The 6-character code (e.g., "ABC123")
- Which child requested it (Minecraft username)
- When it was created
- When it expires (15 minutes later)
- Whether it's been used yet
- Who used it (parent email, IP address)

**Why it exists:** Security measure - codes can only be used once, expire quickly, and are linked to a specific child.

---

### 2. `verification_requests` - Parent Submission Records
**What it does:** Stores when a parent fills out the Wix form to request access for their child.

**Real-world analogy:** Like a permission slip that a parent fills out, waiting for the teacher's approval.

**Key Information Stored:**
- Child's Minecraft username
- Parent's real name and email
- The code the parent used from the form
- Whether parent gave consent (checkbox)
- Whether an adult also wants to join (optional)
- Current status: `pending` → `approved`/`rejected` → `processed`
- Admin notes or rejection reasons
- Timestamps for audit trail

**Why it exists:** Central record of all verification requests. Must be manually approved by an admin - no auto-approval for safety.

**Status Flow:**
```
pending → (admin reviews) → approved/rejected → processed
```

---

### 3. `access_grants` - The Promotion Queue
**What it does:** Stores approved promotions that need to be applied to players in Minecraft (via LuckPerms).

**Real-world analogy:** Like a work order that says "Give this person access to Building B" - waiting to be executed.

**Key Information Stored:**
- Which player to promote
- What to give them: group (e.g., "child" or "adult") OR permission (e.g., "minecraftchurch.volunteer")
- Current status: `approved` → `applied` → `failed` (if error)
- When it was successfully applied
- Error messages if something went wrong
- Links back to the original verification request

**Why it exists:** Separation of concerns - approvals happen in database, then Denizen script polls this table and applies changes to Minecraft server automatically.

**Status Flow:**
```
approved → (Denizen applies) → applied ✅
                         → failed ❌ (logs error)
```

---

### 4. `known_players` - Player Registry
**What it does:** Tracks every player who has ever joined the server.

**Real-world analogy:** Like a guest book that records everyone who visits.

**Key Information Stored:**
- Player's Minecraft username
- Their UUID (unique identifier)
- Platform: Java Edition, Bedrock, or unknown
- First time they joined
- Last time they were seen

**Why it exists:** Audit trail and platform detection. Helps track who's been on the server for safety and compliance purposes.

---

### 5. `audit_log` - Security Camera Footage
**What it does:** Records every important action taken by admins or the system.

**Real-world analogy:** Like a security camera that records all important events.

**Key Information Stored:**
- What action happened (approve, reject, grant_applied, etc.)
- Who did it (admin username)
- Which player was affected
- When it happened
- IP address
- Additional details in JSON format

**Why it exists:** Compliance and safety. Full audit trail of all administrative actions for review if needed.

---

## 🔗 How They Work Together: The Complete Flow

### Step-by-Step Journey of a Child Getting Access

1. **Child joins server** → `known_players` table records them
2. **Child clicks Doorkeeper NPC** → `verification_codes` table gets a new code
3. **Parent fills out Wix form** → `verification_requests` table creates a `pending` entry
4. **Admin reviews request** → `verification_requests` status changes to `approved`
5. **System creates grants** → `access_grants` table gets entries with status `approved`
6. **Denizen script polls** → Reads `access_grants` where status = `approved`
7. **Denizen applies LuckPerms** → Promotes child to "child" group in Minecraft
8. **Denizen marks applied** → `access_grants` status changes to `applied`
9. **Audit log records** → `audit_log` table records each step

---

## ✅ Verification Checklist

When reviewing the schema, verify these key points:

### Structure Verification
- [ ] **5 tables exist:** `verification_codes`, `verification_requests`, `access_grants`, `known_players`, `audit_log`
- [ ] All tables use `utf8mb4` character set (supports emojis and special characters)
- [ ] All tables use `InnoDB` engine (supports foreign keys and transactions)

### Security Verification
- [ ] `verification_codes.code` is PRIMARY KEY (unique, can't duplicate)
- [ ] `verification_requests.status` uses ENUM (can only be: pending, approved, rejected, processed)
- [ ] Foreign key exists: `verification_requests.code` → `verification_codes.code`
- [ ] Foreign key exists: `access_grants.request_id` → `verification_requests.id`
- [ ] Foreign key exists: `audit_log.request_id` → `verification_requests.id` (optional)

### Data Integrity Verification
- [ ] `verification_codes.expires_at` is NOT NULL (codes must expire)
- [ ] `verification_codes.used_at` is NULL by default (codes start unused)
- [ ] `verification_requests.status` defaults to `'pending'` (requires manual approval)
- [ ] `access_grants.status` defaults to `'approved'` (ready for Denizen to apply)
- [ ] All timestamps use TIMESTAMP with automatic defaults

### Indexes Verification
- [ ] Indexes exist on frequently searched fields:
  - `child_name` in verification_codes and verification_requests
  - `status` in verification_requests and access_grants
  - `code` in verification_codes and verification_requests
  - `player_name` in access_grants and known_players
  - `created_at` for time-based queries

### Compliance Verification
- [ ] `audit_log` table exists for compliance tracking
- [ ] `verification_requests.approved_by` field exists (tracks who approved)
- [ ] `verification_requests.approved_at` field exists (tracks when approved)
- [ ] All parent/guardian information fields exist (name, email, consent)
- [ ] IP address tracking exists (`used_ip` in verification_codes, `ip_address` in audit_log)

---

## 🔍 What to Look For: Red Flags

### ❌ Things That Should NOT Be Present

1. **Auto-approval mechanisms** - Status should default to `pending`, never auto-approve
2. **Weak constraints** - Codes should be PRIMARY KEY (unique), not just indexed
3. **Missing indexes** - Without indexes on `status` and `child_name`, queries will be slow
4. **No expiration** - Codes without expiration dates are a security risk
5. **No audit trail** - Missing `audit_log` table or `approved_by` fields
6. **Loose foreign keys** - Should use RESTRICT or CASCADE appropriately

### ✅ Things That SHOULD Be Present

1. **Foreign key constraints** - Ensure data integrity
2. **ENUM types for status** - Prevents invalid status values
3. **NOT NULL constraints** - Critical fields must have values
4. **Default timestamps** - Automatic tracking of when things happen
5. **Indexes on search fields** - Fast queries for child names, status, etc.
6. **Comments on all fields** - Documentation built into the schema

---

## 📊 Quick Reference: Table Relationships

```
┌─────────────────────┐
│ verification_codes  │
│ (code, child_name)  │
└──────────┬──────────┘
           │ (1 code)
           │
           ▼
┌─────────────────────┐
│verification_requests│
│ (id, code, status)  │
└──────────┬──────────┘
           │ (1 request)
           │
           ▼
┌─────────────────────┐
│   access_grants     │
│ (request_id, grant) │
└─────────────────────┘

┌─────────────────────┐
│   known_players     │
│ (player_name, uuid) │
│     (standalone)    │
└─────────────────────┘

┌─────────────────────┐
│    audit_log        │
│ (tracks everything) │
└─────────────────────┘
```

---

## 🎯 Key Design Decisions Explained

### Why 6-character codes?
- Short enough for parents to easily type
- Long enough to be reasonably secure
- Alphanumeric (not shown in schema, but enforced in code generation)

### Why 15-minute expiration?
- Balance between security and usability
- Long enough for parent to find form and fill it out
- Short enough to prevent code sharing/theft

### Why separate `access_grants` table?
- Allows multiple grants per request (child + optional adult)
- Allows tracking grant application status separately
- Enables retry logic if application fails
- Better audit trail

### Why ENUM for status fields?
- Prevents typos ("aproved" vs "approved")
- Database enforces valid values
- Clear documentation of allowed states

### Why FOREIGN KEY constraints?
- Prevents orphaned records
- Ensures data integrity
- Database enforces relationships automatically

---

## 📝 Questions to Ask Yourself

When reviewing, ask:

1. **Security:** Can someone bypass the approval process? (No - status must be manually changed from `pending`)

2. **Compliance:** Can we prove who approved what and when? (Yes - `approved_by`, `approved_at`, `audit_log`)

3. **Safety:** Can codes be reused? (No - marked as used, single-use)

4. **Traceability:** Can we track a child's journey from code request to access grant? (Yes - all linked via foreign keys)

5. **Audit:** If something goes wrong, can we investigate? (Yes - `audit_log` records everything)

---

## ✅ Final Verification Command

After the schema is applied, run this to verify:

```sql
USE minecraft_church;

-- Check all tables exist
SHOW TABLES;

-- Verify table structures
DESCRIBE verification_codes;
DESCRIBE verification_requests;
DESCRIBE access_grants;
DESCRIBE known_players;
DESCRIBE audit_log;

-- Check foreign keys
SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'minecraft_church'
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- Check indexes
SHOW INDEX FROM verification_codes;
SHOW INDEX FROM verification_requests;
SHOW INDEX FROM access_grants;
```

---

## 💡 Summary

This schema is designed with **safety first**:
- ✅ Manual approval required (no auto-approval)
- ✅ Single-use codes with expiration
- ✅ Complete audit trail
- ✅ Data integrity via foreign keys
- ✅ Status tracking at every step
- ✅ Platform detection for Java/Bedrock

Everything is structured to ensure child safety, compliance, and traceability of all actions.
