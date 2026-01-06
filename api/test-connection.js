/**
 * Database Connection Test Script
 * 
 * This script tests the database connection using the credentials from config.js
 * Run with: node test-connection.js
 */

const mysql = require('mysql2/promise');
const config = require('./config.js');

async function testConnection() {
  console.log('Testing database connection...');
  console.log(`Host: ${config.database.host}`);
  console.log(`Port: ${config.database.port}`);
  console.log(`Database: ${config.database.database}`);
  console.log(`User: ${config.database.user}`);
  console.log('Password: [hidden]');
  console.log('');

  try {
    const connection = await mysql.createConnection({
      host: config.database.host,
      port: config.database.port,
      database: config.database.database,
      user: config.database.user,
      password: config.database.password
    });
    
    console.log('✅ Database connection successful!');
    
    // Test a simple query
    const [rows] = await connection.execute('SELECT 1 as test');
    console.log('✅ Query test successful!');
    
    // Check if tables exist
    const [tables] = await connection.execute('SHOW TABLES');
    console.log(`✅ Found ${tables.length} table(s) in database:`);
    tables.forEach(table => {
      console.log(`   - ${Object.values(table)[0]}`);
    });
    
    await connection.end();
    console.log('');
    console.log('✅ All tests passed! Your database is ready to use.');
    process.exit(0);
  } catch (error) {
    console.error('');
    console.error('❌ Database connection failed!');
    console.error(`Error: ${error.message}`);
    console.error('');
    
    // Provide helpful error messages
    if (error.code === 'ECONNREFUSED') {
      console.error('💡 Tip: Make sure MySQL server is running.');
      console.error('   - XAMPP: Start MySQL in XAMPP Control Panel');
      console.error('   - Windows Service: Check services.msc for MySQL service');
    } else if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('💡 Tip: Check your username and password in .env file');
    } else if (error.code === 'ER_BAD_DB_ERROR') {
      console.error('💡 Tip: Database does not exist. Run Step 4 to create it.');
    }
    
    console.error('');
    process.exit(1);
  }
}

testConnection();
