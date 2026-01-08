# CSV Storage System

The API now uses CSV files for data storage instead of MySQL. This makes the system simpler and eliminates the need for a database server.

## Overview

- **Storage**: All data is stored in CSV files in the `api/data/` directory
- **Compatibility**: The CSV module provides a MySQL-compatible interface, so no route changes were needed
- **Tables**: All 5 tables are stored as CSV files:
  - `verification_codes.csv`
  - `verification_requests.csv`
  - `access_grants.csv`
  - `known_players.csv`
  - `audit_log.csv`

## Setup

1. **No Database Configuration Needed**: You don't need to configure MySQL anymore. The `.env` file database settings are ignored.

2. **Automatic Initialization**: CSV files are automatically created when the API starts if they don't exist.

3. **Data Directory**: All CSV files are stored in `api/data/` directory (created automatically).

## How It Works

The `csv-db.js` module:
- Provides a `query()` function that parses SQL-like queries and operates on CSV files
- Supports SELECT, INSERT, UPDATE, and DELETE operations
- Handles WHERE clauses, ORDER BY, LIMIT, and simple JOINs
- Provides transaction-like interface (though CSV doesn't support true transactions)
- Auto-increments IDs for tables that need them

## Advantages

✅ **No Database Server**: No need to install or configure MySQL  
✅ **Simple Setup**: Just run `npm start` and it works  
✅ **Easy Backup**: Just copy the `api/data/` folder  
✅ **Easy Migration**: Can export/import data as CSV easily  
✅ **No Connection Issues**: No database connection timeouts or SSL issues  

## Limitations

⚠️ **Single Process**: File locking is in-memory only, so don't run multiple API instances  
⚠️ **No True Transactions**: Rollback doesn't actually undo file writes  
⚠️ **Slower for Large Data**: CSV is slower than MySQL for very large datasets  
⚠️ **Limited Query Features**: Complex SQL features may not work  

## Migration from MySQL

If you had data in MySQL and want to migrate:

1. Export your MySQL data to CSV files matching the table structure
2. Copy the CSV files to `api/data/` directory
3. Make sure headers match exactly (first row of each CSV)

## File Structure

```
api/
├── data/                    # CSV files directory (auto-created)
│   ├── verification_codes.csv
│   ├── verification_requests.csv
│   ├── access_grants.csv
│   ├── known_players.csv
│   └── audit_log.csv
├── csv-db.js               # CSV storage module
├── db.js                   # Re-exports csv-db.js for compatibility
└── ...
```

## Troubleshooting

**Issue**: Data not persisting
- **Solution**: Make sure the `api/data/` directory is writable

**Issue**: "Table not found" errors
- **Solution**: Delete the `api/data/` directory and restart the API (it will recreate the files)

**Issue**: Corrupted CSV files
- **Solution**: Delete the corrupted file and restart the API (it will recreate with headers)

## Notes

- CSV files are UTF-8 encoded
- Dates are stored as ISO 8601 strings
- Boolean values are stored as 1/0
- NULL values are stored as empty strings
