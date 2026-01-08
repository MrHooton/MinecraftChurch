/**
 * CSV Database Module
 * File-based CSV storage to replace MySQL
 * Handles reading, writing, and querying CSV files
 */

const fs = require('fs').promises;
const path = require('path');

// CSV file paths
const DATA_DIR = path.join(__dirname, 'data');
const TABLES = {
  verification_codes: path.join(DATA_DIR, 'verification_codes.csv'),
  verification_requests: path.join(DATA_DIR, 'verification_requests.csv'),
  access_grants: path.join(DATA_DIR, 'access_grants.csv'),
  known_players: path.join(DATA_DIR, 'known_players.csv'),
  audit_log: path.join(DATA_DIR, 'audit_log.csv')
};

// In-memory lock for file operations (simple but works for single process)
const locks = {};

/**
 * Acquire a lock for a file
 */
async function acquireLock(tableName) {
  if (!locks[tableName]) {
    locks[tableName] = Promise.resolve();
  }
  const waitFor = locks[tableName];
  locks[tableName] = waitFor.then(() => {
    return new Promise((resolve) => {
      resolve();
    });
  });
  await waitFor;
}

/**
 * Release a lock
 */
function releaseLock(tableName) {
  // Lock is automatically released when promise resolves
}

/**
 * Ensure data directory exists
 */
async function ensureDataDir() {
  try {
    await fs.mkdir(DATA_DIR, { recursive: true });
  } catch (error) {
    if (error.code !== 'EEXIST') {
      throw error;
    }
  }
}

/**
 * Parse CSV row to object
 */
function parseRow(row, headers) {
  const obj = {};
  headers.forEach((header, index) => {
    let value = row[index] || '';
    // Try to parse as number if possible
    if (value === '') {
      obj[header] = null;
    } else if (value === 'true' || value === 'false') {
      obj[header] = value === 'true';
    } else if (!isNaN(value) && value !== '') {
      // Check if it's an integer or float
      const num = Number(value);
      obj[header] = num;
    } else {
      obj[header] = value;
    }
  });
  return obj;
}

/**
 * Convert object to CSV row
 */
function objectToRow(obj, headers) {
  return headers.map(header => {
    const value = obj[header];
    if (value === null || value === undefined) {
      return '';
    }
    if (typeof value === 'boolean') {
      return value ? '1' : '0';
    }
    // Escape commas and quotes in CSV
    const str = String(value);
    if (str.includes(',') || str.includes('"') || str.includes('\n')) {
      return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
  });
}

/**
 * Read CSV file and return array of objects
 */
async function readCSV(filePath) {
  await acquireLock(filePath);
  try {
    await ensureDataDir();
    const content = await fs.readFile(filePath, 'utf-8').catch(() => '');
    
    if (!content.trim()) {
      return { headers: [], rows: [] };
    }

    const lines = content.trim().split('\n');
    if (lines.length === 0) {
      return { headers: [], rows: [] };
    }

    const headers = lines[0].split(',').map(h => h.trim().replace(/^"|"$/g, ''));
    const rows = lines.slice(1).map(line => {
      // Simple CSV parsing (handles quoted values)
      const row = [];
      let current = '';
      let inQuotes = false;
      
      for (let i = 0; i < line.length; i++) {
        const char = line[i];
        if (char === '"') {
          if (inQuotes && line[i + 1] === '"') {
            current += '"';
            i++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (char === ',' && !inQuotes) {
          row.push(current.trim());
          current = '';
        } else {
          current += char;
        }
      }
      row.push(current.trim());
      return row;
    }).filter(row => row.length > 0);

    const data = rows.map(row => parseRow(row, headers));
    return { headers, rows: data };
  } finally {
    releaseLock(filePath);
  }
}

/**
 * Write array of objects to CSV file
 */
async function writeCSV(filePath, headers, rows) {
  await acquireLock(filePath);
  try {
    await ensureDataDir();
    
    const csvRows = [headers.join(',')];
    rows.forEach(row => {
      csvRows.push(objectToRow(row, headers).join(','));
    });
    
    await fs.writeFile(filePath, csvRows.join('\n') + '\n', 'utf-8');
  } finally {
    releaseLock(filePath);
  }
}

/**
 * Initialize CSV files with headers if they don't exist
 */
async function initializeTables() {
  await ensureDataDir();

  // verification_codes
  try {
    await fs.access(TABLES.verification_codes);
  } catch {
    const headers = ['code', 'child_name', 'child_uuid', 'created_at', 'expires_at', 'used_at', 'used_by_email', 'used_ip'];
    await writeCSV(TABLES.verification_codes, headers, []);
  }

  // verification_requests
  try {
    await fs.access(TABLES.verification_requests);
  } catch {
    const headers = ['id', 'child_name', 'adult_name', 'code', 'parent_name', 'parent_email', 'consent', 'church', 'adult_join', 'status', 'approved_by', 'approved_at', 'notes', 'created_at', 'updated_at'];
    await writeCSV(TABLES.verification_requests, headers, []);
  }

  // access_grants
  try {
    await fs.access(TABLES.access_grants);
  } catch {
    const headers = ['id', 'request_id', 'player_name', 'grant_type', 'grant_value', 'status', 'applied_at', 'error', 'created_at', 'updated_at'];
    await writeCSV(TABLES.access_grants, headers, []);
  }

  // known_players
  try {
    await fs.access(TABLES.known_players);
  } catch {
    const headers = ['player_name', 'uuid', 'platform', 'first_seen_at', 'last_seen_at'];
    await writeCSV(TABLES.known_players, headers, []);
  }

  // audit_log
  try {
    await fs.access(TABLES.audit_log);
  } catch {
    const headers = ['id', 'action_type', 'admin_user', 'target_player', 'request_id', 'grant_id', 'details', 'ip_address', 'created_at'];
    await writeCSV(TABLES.audit_log, headers, []);
  }
}

/**
 * Get next auto-increment ID for a table
 */
async function getNextId(tableName) {
  const { rows } = await readCSV(TABLES[tableName]);
  if (rows.length === 0) return 1;
  const ids = rows.map(row => row.id || 0).filter(id => typeof id === 'number');
  return Math.max(...ids, 0) + 1;
}

/**
 * Evaluate WHERE clause
 */
function evaluateWhereClause(whereClause, row, params) {
  // Simple WHERE evaluation for common patterns
  let clause = whereClause;
  const paramPattern = /\?/g;
  let paramIndex = 0;
  clause = clause.replace(paramPattern, () => {
    const value = params[paramIndex++];
    if (typeof value === 'string') {
      return `"${value}"`;
    }
    return String(value);
  });

  // Evaluate simple conditions
  const conditions = clause.split(/\s+and\s+/i);
  
  return conditions.every(condition => {
    condition = condition.trim();
    
    // column = value
    const eqMatch = condition.match(/(\w+)\.(\w+)\s*=\s*(.+)/) || condition.match(/(\w+)\s*=\s*(.+)/);
    if (eqMatch) {
      const col = eqMatch[eqMatch.length === 3 ? 1 : 2].trim();
      let val = eqMatch[eqMatch.length === 3 ? 2 : 1].trim().replace(/^["']|["']$/g, '');
      if (val === 'NULL' || val === 'null') {
        return row[col] === null || row[col] === undefined;
      }
      if (!isNaN(val) && val !== '') {
        val = Number(val);
      }
      return String(row[col]).toLowerCase() === String(val).toLowerCase() || row[col] == val;
    }

    // column != value
    const neMatch = condition.match(/(\w+)\.(\w+)\s*!=\s*(.+)/) || condition.match(/(\w+)\s*!=\s*(.+)/);
    if (neMatch) {
      const col = neMatch[neMatch.length === 3 ? 1 : 2].trim();
      let val = neMatch[neMatch.length === 3 ? 2 : 1].trim().replace(/^["']|["']$/g, '');
      if (val === 'NULL' || val === 'null') {
        return row[col] !== null && row[col] !== undefined;
      }
      if (!isNaN(val) && val !== '') {
        val = Number(val);
      }
      return String(row[col]).toLowerCase() !== String(val).toLowerCase() && row[col] != val;
    }

    // column IN (value1, value2, ...)
    const inMatch = condition.match(/(\w+)\.(\w+)\s+in\s+\((.+)\)/i) || condition.match(/(\w+)\s+in\s+\((.+)\)/i);
    if (inMatch) {
      const col = inMatch[inMatch.length === 2 ? 1 : 2].trim();
      const values = inMatch[inMatch.length === 2 ? 0 : 1].split(',').map(v => {
        v = v.trim().replace(/^["']|["']$/g, '');
        if (!isNaN(v) && v !== '') return Number(v);
        return v;
      });
      return values.includes(row[col]) || values.includes(String(row[col]));
    }

    // column IS NULL
    const isNullMatch = condition.match(/(\w+)\.(\w+)\s+is\s+null/i) || condition.match(/(\w+)\s+is\s+null/i);
    if (isNullMatch) {
      const col = isNullMatch[isNullMatch.length === 1 ? 1 : 2].trim();
      return row[col] === null || row[col] === undefined;
    }

    return true; // Default to true if can't parse
  });
}

/**
 * Handle SELECT queries
 */
async function handleSelect(sql, params) {
  const sqlLower = sql.toLowerCase();
  // Extract table name
  const tableMatch = sql.match(/from\s+(\w+)/i);
  if (!tableMatch) {
    throw new Error('Could not determine table from SELECT query');
  }
  const tableName = tableMatch[1];
  
  if (!TABLES[tableName]) {
    throw new Error(`Table ${tableName} not found`);
  }

  const { rows } = await readCSV(TABLES[tableName]);
  
  // Parse WHERE clause
  let filteredRows = rows;
  const whereMatch = sql.match(/where\s+(.+?)(?:\s+order\s+by|\s+limit|$)/i);
  if (whereMatch) {
    const whereClause = whereMatch[1];
    filteredRows = rows.filter(row => {
      return evaluateWhereClause(whereClause, row, params);
    });
  }

  // Handle JOINs (simple INNER JOIN only)
  if (sqlLower.includes('inner join')) {
    const joinMatch = sql.match(/inner join\s+(\w+)\s+on\s+(\w+)\.(\w+)\s*=\s*(\w+)\.(\w+)/i);
    if (joinMatch) {
      const joinTable = joinMatch[1];
      const { rows: joinRows } = await readCSV(TABLES[joinTable]);
      filteredRows = filteredRows.map(row => {
        const joinRow = joinRows.find(jr => {
          // Support both directions of join
          if (joinMatch[2] === tableName) {
            return String(jr[joinMatch[5]]) === String(row[joinMatch[3]]);
          } else {
            return String(jr[joinMatch[3]]) === String(row[joinMatch[5]]);
          }
        });
        if (joinRow) {
          return { ...row, ...joinRow };
        }
        return null;
      }).filter(r => r !== null);
    }
  }

  // Parse ORDER BY
  const orderMatch = sql.match(/order\s+by\s+(\w+)\.(\w+)(?:\s+(asc|desc))?/i) || sql.match(/order\s+by\s+(\w+)(?:\s+(asc|desc))?/i);
  if (orderMatch) {
    const orderColumn = orderMatch[orderMatch.length === 2 ? 1 : 2].trim();
    const orderDir = (orderMatch[orderMatch.length === 2 ? 0 : orderMatch.length - 1] || 'asc').toLowerCase();
    filteredRows.sort((a, b) => {
      const aVal = a[orderColumn];
      const bVal = b[orderColumn];
      if (aVal === null || aVal === undefined) return 1;
      if (bVal === null || bVal === undefined) return -1;
      if (typeof aVal === 'string') {
        const comparison = aVal.toLowerCase() > bVal.toLowerCase() ? 1 : aVal.toLowerCase() < bVal.toLowerCase() ? -1 : 0;
        return orderDir === 'desc' ? -comparison : comparison;
      }
      const comparison = aVal > bVal ? 1 : aVal < bVal ? -1 : 0;
      return orderDir === 'desc' ? -comparison : comparison;
    });
  }

  // Parse LIMIT
  const limitMatch = sql.match(/limit\s+(\d+)(?:\s*,\s*(\d+))?/i);
  if (limitMatch) {
    const limit = parseInt(limitMatch[1]);
    const offset = limitMatch[2] ? parseInt(limitMatch[2]) : 0;
    filteredRows = filteredRows.slice(offset, offset + limit);
  } else {
    const limitMatch2 = sql.match(/limit\s+(\d+)\s+offset\s+(\d+)/i);
    if (limitMatch2) {
      const limit = parseInt(limitMatch2[1]);
      const offset = parseInt(limitMatch2[2]);
      filteredRows = filteredRows.slice(offset, offset + limit);
    }
  }

  // Handle SELECT specific columns
  const selectMatch = sql.match(/select\s+(.+?)\s+from/i);
  if (selectMatch && !selectMatch[1].includes('*')) {
    const columns = selectMatch[1].split(',').map(c => c.trim().split('.').pop().trim());
    filteredRows = filteredRows.map(row => {
      const result = {};
      columns.forEach(col => {
        if (row.hasOwnProperty(col)) {
          result[col] = row[col];
        }
      });
      return result;
    });
  }

  return filteredRows;
}

/**
 * Handle INSERT queries
 */
async function handleInsert(sql, params) {
  const insertMatch = sql.match(/insert\s+into\s+(\w+)\s*\(([^)]+)\)\s*values\s*\((.+)\)/i);
  if (!insertMatch) {
    throw new Error('Could not parse INSERT query');
  }

  const tableName = insertMatch[1];
  const columns = insertMatch[2].split(',').map(c => c.trim());
  const placeholders = insertMatch[3].split(',').map(p => p.trim());

  if (!TABLES[tableName]) {
    throw new Error(`Table ${tableName} not found`);
  }

  const { headers, rows } = await readCSV(TABLES[tableName]);
  
  // Create new row
  const newRow = {};
  let paramIndex = 0;
  columns.forEach((col, index) => {
    let value;
    const placeholder = placeholders[index];
    if (placeholder === 'NOW()' || placeholder === 'CURRENT_TIMESTAMP') {
      value = new Date().toISOString();
    } else if (placeholder === '?') {
      value = params[paramIndex++];
      // Convert Date objects to ISO strings
      if (value instanceof Date) {
        value = value.toISOString();
      }
      // Convert boolean to 1/0
      if (typeof value === 'boolean') {
        value = value ? 1 : 0;
      }
    } else {
      value = placeholder.replace(/^["']|["']$/g, '');
    }
    
    // Handle NULL
    if (value === null || value === undefined || value === 'NULL') {
      newRow[col] = null;
    } else {
      newRow[col] = value;
    }
  });

  // Auto-increment ID if needed
  if (!newRow.id && headers.includes('id')) {
    newRow.id = await getNextId(tableName);
  }

  // Set timestamps
  const now = new Date().toISOString();
  if (headers.includes('created_at') && !newRow.created_at) {
    newRow.created_at = now;
  }
  if (headers.includes('updated_at') && !newRow.updated_at) {
    newRow.updated_at = now;
  }
  if (headers.includes('first_seen_at') && !newRow.first_seen_at) {
    newRow.first_seen_at = now;
  }
  if (headers.includes('last_seen_at') && !newRow.last_seen_at) {
    newRow.last_seen_at = now;
  }

  rows.push(newRow);
  await writeCSV(TABLES[tableName], headers, rows);

  // Return MySQL-compatible result
  return {
    insertId: newRow.id || rows.length,
    affectedRows: 1
  };
}

/**
 * Handle UPDATE queries
 */
async function handleUpdate(sql, params) {
  const updateMatch = sql.match(/update\s+(\w+)\s+set\s+(.+?)(?:\s+where|\s*$)/i);
  if (!updateMatch) {
    throw new Error('Could not parse UPDATE query');
  }

  const tableName = updateMatch[1];
  const setClause = updateMatch[2];
  
  if (!TABLES[tableName]) {
    throw new Error(`Table ${tableName} not found`);
  }

  const { headers, rows } = await readCSV(TABLES[tableName]);

  // Parse SET clause
  const setPairs = setClause.split(',').map(pair => {
    const match = pair.match(/(\w+)\s*=\s*(.+)/);
    if (!match) return null;
    return { column: match[1].trim(), value: match[2].trim() };
  }).filter(p => p !== null);

  // Parse WHERE clause
  const whereMatch = sql.match(/where\s+(.+?)(?:\s*$)/i);
  let whereClause = whereMatch ? whereMatch[1] : null;

  // Count how many params are used in SET clause (for ? placeholders)
  let setParamCount = 0;
  setPairs.forEach(({ value }) => {
    if (value === '?') {
      setParamCount++;
    } else if (value.startsWith('COALESCE')) {
      const coalesceMatch = value.match(/coalesce\((.+?)\)/i);
      if (coalesceMatch) {
        const args = coalesceMatch[1].split(',').map(a => a.trim());
        if (args[0] === '?') {
          setParamCount++;
        }
      }
    }
  });

  let affectedRows = 0;
  rows.forEach((row) => {
    let shouldUpdate = true;
    
    if (whereClause) {
      // Use remaining params for WHERE clause
      const whereParams = params.slice(setParamCount);
      shouldUpdate = evaluateWhereClause(whereClause, row, whereParams);
    }

    if (shouldUpdate) {
      let setParamIndex = 0;
      setPairs.forEach(({ column, value }) => {
        let val = value;
        if (value === 'NOW()' || value === 'CURRENT_TIMESTAMP') {
          val = new Date().toISOString();
        } else if (value === '?') {
          val = params[setParamIndex++];
          // Convert Date objects to ISO strings
          if (val instanceof Date) {
            val = val.toISOString();
          }
          // Convert boolean to 1/0
          if (typeof val === 'boolean') {
            val = val ? 1 : 0;
          }
        } else if (value === 'NULL') {
          val = null;
        } else if (value.startsWith('COALESCE')) {
          // Simple COALESCE handling: COALESCE(?, uuid)
          const coalesceMatch = value.match(/coalesce\((.+?)\)/i);
          if (coalesceMatch) {
            const args = coalesceMatch[1].split(',').map(a => a.trim());
            const firstArg = args[0];
            if (firstArg === '?') {
              val = params[setParamIndex++] || row[args[1].trim()];
            } else {
              val = row[args[1].trim()] || params[setParamIndex++];
            }
          }
        } else if (!isNaN(value) && value !== '') {
          val = Number(value);
        } else {
          val = value.replace(/^["']|["']$/g, '');
        }
        row[column] = val;
      });

      // Auto-update updated_at timestamp
      if (headers.includes('updated_at')) {
        row.updated_at = new Date().toISOString();
      }
      if (headers.includes('last_seen_at')) {
        row.last_seen_at = new Date().toISOString();
      }

      affectedRows++;
    }
  });

  await writeCSV(TABLES[tableName], headers, rows);

  return { affectedRows };
}

/**
 * Handle DELETE queries (not used but included for completeness)
 */
async function handleDelete(sql, params) {
  const deleteMatch = sql.match(/delete\s+from\s+(\w+)(?:\s+where|\s*$)/i);
  if (!deleteMatch) {
    throw new Error('Could not parse DELETE query');
  }

  const tableName = deleteMatch[1];
  if (!TABLES[tableName]) {
    throw new Error(`Table ${tableName} not found`);
  }

  const { headers, rows } = await readCSV(TABLES[tableName]);

  const whereMatch = sql.match(/where\s+(.+?)(?:\s*$)/i);
  let whereClause = whereMatch ? whereMatch[1] : null;

  const filteredRows = whereClause 
    ? rows.filter(row => !evaluateWhereClause(whereClause, row, params))
    : [];

  await writeCSV(TABLES[tableName], headers, filteredRows);

  return { affectedRows: rows.length - filteredRows.length };
}

/**
 * Query-like interface compatible with MySQL queries
 */
async function query(sql, params = []) {
  // Parse SQL to determine operation and table
  const sqlLower = sql.toLowerCase().trim();
  
  // SELECT queries
  if (sqlLower.startsWith('select')) {
    return await handleSelect(sql, params);
  }
  
  // INSERT queries
  if (sqlLower.startsWith('insert')) {
    return await handleInsert(sql, params);
  }
  
  // UPDATE queries
  if (sqlLower.startsWith('update')) {
    return await handleUpdate(sql, params);
  }
  
  // DELETE queries
  if (sqlLower.startsWith('delete')) {
    return await handleDelete(sql, params);
  }
  
  // SHOW TABLES
  if (sqlLower.includes('show tables')) {
    return Object.keys(TABLES).map(name => ({ [`Tables_in_${path.basename(DATA_DIR)}`]: name }));
  }
  
  throw new Error(`Unsupported SQL operation: ${sql.substring(0, 50)}`);
}

/**
 * Test connection (for compatibility)
 */
async function testConnection() {
  try {
    await initializeTables();
    console.log('✅ CSV storage initialized successfully!');
    console.log(`Data directory: ${DATA_DIR}`);
    return true;
  } catch (error) {
    console.error('❌ CSV storage initialization failed:', error.message);
    return false;
  }
}

/**
 * Get connection (for compatibility with transaction code)
 * Returns a mock connection object that works like MySQL connection
 */
async function getConnection() {
  await initializeTables();
  
  const mockConnection = {
    changes: [],
    
    async beginTransaction() {
      // CSV doesn't support transactions, but we'll track changes
      this.changes = [];
    },
    
    async execute(sql, params = []) {
      const result = await query(sql, params);
      // MySQL execute returns [result, fields], but we don't have fields
      return [result]; 
    },
    
    async commit() {
      // Commit is a no-op for CSV (already written)
      this.changes = [];
    },
    
    async rollback() {
      // Rollback is a no-op for CSV (can't undo file writes)
      this.changes = [];
    },
    
    release() {
      // No-op
    }
  };
  
  return mockConnection;
}

// Initialize on module load
initializeTables().catch(err => {
  console.error('Failed to initialize CSV tables:', err);
});

module.exports = {
  query,
  getConnection,
  testConnection,
  initializeTables
};
