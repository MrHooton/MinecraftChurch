# Important: Database Name Configuration

## Current Situation

Your Apex MySQL server provided database name: `apexMC2969109`

The schema files expect database name: `minecraft_church`

## Options

### Option 1: Use Apex Database Name (Recommended for Quick Start)

1. The `.env` file is already configured with `DB_NAME=apexMC2969109`
2. Run the schema SQL directly in your Apex database:
   - Connect to your Apex MySQL via phpMyAdmin or MySQL client
   - Select database `apexMC2969109`
   - Run the contents of `database/schema.sql`

### Option 2: Create New Database in Apex (Recommended for Clean Setup)

1. Create a new database named `minecraft_church` in your Apex MySQL:
   ```sql
   CREATE DATABASE minecraft_church 
   CHARACTER SET utf8mb4 
   COLLATE utf8mb4_unicode_ci;
   ```

2. Update `.env` file:
   ```env
   DB_NAME=minecraft_church
   ```

3. Run the schema:
   - Connect to Apex MySQL
   - Select database `minecraft_church`
   - Run the contents of `database/schema.sql`

### Option 3: Keep Apex Name, Update Schema

If you prefer to keep using `apexMC2969109`:
- The `.env` is already configured correctly
- Just run the schema SQL in that database

## Recommended: Option 2

Creating a dedicated `minecraft_church` database keeps things organized and matches the documentation. You can create it via:
- Apex control panel (if available)
- phpMyAdmin at `https://mysql.apexhosting.gdn/`
- MySQL command line

## Next Steps

1. Choose your option above
2. Run the schema SQL in your chosen database
3. Test connection: `node test-connection.js`
4. Start the API: `npm start`
