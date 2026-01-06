# Schema Verification Checklist

Use this checklist to verify the database schema is correctly implemented.

## Pre-Installation Verification

### File Check
- [ ] `schema.sql` file exists and is readable
- [ ] File size is reasonable (should be ~5-10 KB)
- [ ] File contains all 5 table definitions
- [ ] No syntax errors visible in the file

---

## Installation Verification

### Database Setup
- [ ] Database `minecraft_church` exists
- [ ] Database uses `utf8mb4` character set
- [ ] Database uses `utf8mb4_unicode_ci` collation

### Table Creation
Run this command after installation:
```sql
USE minecraft_church;
SHOW TABLES;
```

Expected output should show:
- [ ] `verification_codes`
- [ ] `verification_requests`
- [ ] `access_grants`
- [ ] `known_players`
- [ ] `audit_log`

---

## Table Structure Verification

### 1. verification_codes Table

```sql
DESCRIBE verification_codes;
```

Check for:
- [ ] `code` field exists, type is `VARCHAR(6)`, is PRIMARY KEY
- [ ] `child_name` field exists, type is `VARCHAR(16)`, is NOT NULL
- [ ] `child_uuid` field exists, type is `VARCHAR(36)`, is NULL (optional)
- [ ] `created_at` field exists, type is `TIMESTAMP`, has DEFAULT
- [ ] `expires_at` field exists, type is `TIMESTAMP`, is NOT NULL
- [ ] `used_at` field exists, type is `TIMESTAMP`, is NULL (default)
- [ ] `used_by_email` field exists, type is `VARCHAR(255)`, is NULL (optional)
- [ ] `used_ip` field exists, type is `VARCHAR(45)`, is NULL (optional)

**Index check:**
```sql
SHOW INDEX FROM verification_codes;
```
- [ ] Index on `child_name` exists
- [ ] Index on `expires_at` exists
- [ ] Index on `used_at` exists
- [ ] Index on `created_at` exists

### 2. verification_requests Table

```sql
DESCRIBE verification_requests;
```

Check for:
- [ ] `id` field exists, type is `INT`, is AUTO_INCREMENT, is PRIMARY KEY
- [ ] `child_name` field exists, type is `VARCHAR(16)`, is NOT NULL
- [ ] `adult_name` field exists, type is `VARCHAR(16)`, is NULL (optional)
- [ ] `code` field exists, type is `VARCHAR(6)`, is NOT NULL
- [ ] `parent_name` field exists, type is `VARCHAR(255)`, is NOT NULL
- [ ] `parent_email` field exists, type is `VARCHAR(255)`, is NOT NULL
- [ ] `consent` field exists, type is `TINYINT(1)`, is NOT NULL, default is 0
- [ ] `church` field exists, type is `VARCHAR(255)`, is NULL (optional)
- [ ] `adult_join` field exists, type is `TINYINT(1)`, is NOT NULL, default is 0
- [ ] `status` field exists, type is `ENUM`, contains: 'pending', 'approved', 'rejected', 'processed'
- [ ] `status` field default is 'pending' ⚠️ **CRITICAL - Must be 'pending'**
- [ ] `approved_by` field exists, type is `VARCHAR(255)`, is NULL (optional)
- [ ] `approved_at` field exists, type is `TIMESTAMP`, is NULL (optional)
- [ ] `notes` field exists, type is `TEXT`, is NULL (optional)
- [ ] `created_at` field exists, type is `TIMESTAMP`, has DEFAULT
- [ ] `updated_at` field exists, type is `TIMESTAMP`, has ON UPDATE CURRENT_TIMESTAMP

**Foreign key check:**
```sql
SELECT 
    CONSTRAINT_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'minecraft_church'
  AND TABLE_NAME = 'verification_requests'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
```
- [ ] Foreign key exists: `code` → `verification_codes.code`

**Index check:**
```sql
SHOW INDEX FROM verification_requests;
```
- [ ] Index on `child_name` exists
- [ ] Index on `adult_name` exists
- [ ] Index on `code` exists
- [ ] Index on `status` exists ⚠️ **CRITICAL for performance**
- [ ] Index on `parent_email` exists
- [ ] Index on `created_at` exists

### 3. access_grants Table

```sql
DESCRIBE access_grants;
```

Check for:
- [ ] `id` field exists, type is `INT`, is AUTO_INCREMENT, is PRIMARY KEY
- [ ] `request_id` field exists, type is `INT`, is NOT NULL
- [ ] `player_name` field exists, type is `VARCHAR(16)`, is NOT NULL
- [ ] `grant_type` field exists, type is `ENUM`, contains: 'group', 'permission'
- [ ] `grant_value` field exists, type is `VARCHAR(255)`, is NOT NULL
- [ ] `status` field exists, type is `ENUM`, contains: 'approved', 'applied', 'failed'
- [ ] `status` field default is 'approved' ⚠️ **CRITICAL for Denizen polling**
- [ ] `applied_at` field exists, type is `TIMESTAMP`, is NULL (optional)
- [ ] `error` field exists, type is `TEXT`, is NULL (optional)
- [ ] `created_at` field exists, type is `TIMESTAMP`, has DEFAULT
- [ ] `updated_at` field exists, type is `TIMESTAMP`, has ON UPDATE CURRENT_TIMESTAMP

**Foreign key check:**
```sql
SELECT 
    CONSTRAINT_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'minecraft_church'
  AND TABLE_NAME = 'access_grants'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
```
- [ ] Foreign key exists: `request_id` → `verification_requests.id` with ON DELETE CASCADE

**Index check:**
```sql
SHOW INDEX FROM access_grants;
```
- [ ] Index on `request_id` exists
- [ ] Index on `player_name` exists
- [ ] Index on `status` exists ⚠️ **CRITICAL for Denizen polling**
- [ ] Index on `grant_type` exists
- [ ] Index on `created_at` exists

### 4. known_players Table

```sql
DESCRIBE known_players;
```

Check for:
- [ ] `player_name` field exists, type is `VARCHAR(16)`, is PRIMARY KEY
- [ ] `uuid` field exists, type is `VARCHAR(36)`, is NULL (optional - for Bedrock)
- [ ] `platform` field exists, type is `ENUM`, contains: 'java', 'bedrock', 'unknown'
- [ ] `platform` field default is 'unknown'
- [ ] `first_seen_at` field exists, type is `TIMESTAMP`, has DEFAULT
- [ ] `last_seen_at` field exists, type is `TIMESTAMP`, has DEFAULT and ON UPDATE CURRENT_TIMESTAMP

**Index check:**
```sql
SHOW INDEX FROM known_players;
```
- [ ] Index on `uuid` exists
- [ ] Index on `platform` exists
- [ ] Index on `last_seen_at` exists

### 5. audit_log Table

```sql
DESCRIBE audit_log;
```

Check for:
- [ ] `id` field exists, type is `INT`, is AUTO_INCREMENT, is PRIMARY KEY
- [ ] `action_type` field exists, type is `VARCHAR(50)`, is NOT NULL
- [ ] `admin_user` field exists, type is `VARCHAR(255)`, is NULL (optional)
- [ ] `target_player` field exists, type is `VARCHAR(16)`, is NULL (optional)
- [ ] `request_id` field exists, type is `INT`, is NULL (optional)
- [ ] `grant_id` field exists, type is `INT`, is NULL (optional)
- [ ] `details` field exists, type is `JSON`, is NULL (optional)
- [ ] `ip_address` field exists, type is `VARCHAR(45)`, is NULL (optional)
- [ ] `created_at` field exists, type is `TIMESTAMP`, has DEFAULT

**Foreign key check:**
```sql
SELECT 
    CONSTRAINT_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'minecraft_church'
  AND TABLE_NAME = 'audit_log'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
```
- [ ] Foreign key exists: `request_id` → `verification_requests.id` with ON DELETE SET NULL
- [ ] Foreign key exists: `grant_id` → `access_grants.id` with ON DELETE SET NULL

**Index check:**
```sql
SHOW INDEX FROM audit_log;
```
- [ ] Index on `action_type` exists
- [ ] Index on `admin_user` exists
- [ ] Index on `target_player` exists
- [ ] Index on `request_id` exists
- [ ] Index on `created_at` exists

---

## Data Integrity Verification

### Test 1: Foreign Key Constraint Test

```sql
-- This should FAIL (code doesn't exist)
INSERT INTO verification_requests 
    (child_name, code, parent_name, parent_email, consent) 
VALUES 
    ('TestChild', 'INVALID', 'Test Parent', 'test@example.com', 1);
```

- [ ] Error occurs: Foreign key constraint fails ⚠️ **This is expected and correct**

### Test 2: Status Enum Test

```sql
-- This should FAIL (invalid status)
INSERT INTO verification_requests 
    (child_name, code, parent_name, parent_email, consent, status) 
VALUES 
    ('TestChild', 'ABC123', 'Test Parent', 'test@example.com', 1, 'invalid_status');
```

- [ ] Error occurs: Invalid enum value ⚠️ **This is expected and correct**

### Test 3: Code Uniqueness Test

```sql
-- Create a code
INSERT INTO verification_codes (code, child_name, expires_at)
VALUES ('TEST01', 'TestChild', DATE_ADD(NOW(), INTERVAL 15 MINUTE));

-- Try to create duplicate code (should FAIL)
INSERT INTO verification_codes (code, child_name, expires_at)
VALUES ('TEST01', 'AnotherChild', DATE_ADD(NOW(), INTERVAL 15 MINUTE));
```

- [ ] Error occurs: Duplicate entry for key 'PRIMARY' ⚠️ **This is expected and correct**

---

## Performance Verification

### Index Usage Test

```sql
-- Check that indexes are being used
EXPLAIN SELECT * FROM verification_requests WHERE status = 'pending';
```

- [ ] Output shows `key` column is not NULL (index is used)
- [ ] `rows` column shows a reasonable number

```sql
EXPLAIN SELECT * FROM access_grants WHERE status = 'approved';
```

- [ ] Output shows `key` column is not NULL (index is used)

---

## Security Verification

### Check 1: Default Status Values

```sql
-- Create a test request (without specifying status)
INSERT INTO verification_requests 
    (child_name, code, parent_name, parent_email, consent) 
VALUES 
    ('TestChild', 'TEST02', 'Test Parent', 'test@example.com', 1);

-- Check the status
SELECT status FROM verification_requests WHERE child_name = 'TestChild';
```

- [ ] Status is 'pending' ⚠️ **CRITICAL - Must default to pending**

### Check 2: Code Expiration

```sql
-- Verify expiration field exists and is required
DESCRIBE verification_codes;
```

- [ ] `expires_at` is NOT NULL (cannot be missing)

---

## Character Set Verification

```sql
-- Check database character set
SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'minecraft_church';
```

- [ ] Character set is `utf8mb4`
- [ ] Collation is `utf8mb4_unicode_ci`

```sql
-- Check table character sets
SELECT TABLE_NAME, TABLE_COLLATION
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'minecraft_church';
```

- [ ] All tables use `utf8mb4_unicode_ci`

---

## Final Verification Script

Run this complete verification script:

```sql
USE minecraft_church;

-- 1. Count tables
SELECT COUNT(*) as table_count FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'minecraft_church' AND TABLE_TYPE = 'BASE TABLE';
-- Should return: 5

-- 2. Check foreign keys
SELECT COUNT(*) as fk_count FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'minecraft_church' 
  AND REFERENCED_TABLE_NAME IS NOT NULL;
-- Should return: 4 (or more if audit_log FKs exist)

-- 3. Check indexes
SELECT TABLE_NAME, COUNT(*) as index_count
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'minecraft_church'
GROUP BY TABLE_NAME;
-- Each table should have multiple indexes

-- 4. Check ENUM values
SELECT COLUMN_NAME, COLUMN_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'minecraft_church'
  AND DATA_TYPE = 'enum';
-- Should show status fields with correct enum values

-- 5. Verify defaults
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_DEFAULT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'minecraft_church'
  AND COLUMN_DEFAULT IS NOT NULL
ORDER BY TABLE_NAME, ORDINAL_POSITION;
-- Check that status defaults are correct
```

---

## ✅ Verification Complete

If all checks pass, the schema is correctly implemented and ready for use!

**Next Steps:**
1. Configure API database connection (Task 2)
2. Implement API endpoints (Task 3)
3. Set up Denizen scripts (Tasks 4-8)
