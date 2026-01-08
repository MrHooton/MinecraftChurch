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
    // Try with SSL first if configured
    let connectionConfig = {
      host: config.database.host,
      port: config.database.port,
      database: config.database.database,
      user: config.database.user,
      password: config.database.password,
      connectTimeout: 10000,
      ssl: config.database.ssl
    };
    
    const connection = await mysql.createConnection(connectionConfig);
    
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
    console.error(`Error Code: ${error.code || 'UNKNOWN'}`);
    console.error(`Error Message: ${error.message}`);
    if (error.errno) {
      console.error(`Error Number: ${error.errno}`);
    }
    console.error('');
    
    // Provide helpful error messages
    if (error.code === 'ECONNREFUSED') {
      console.error('💡 Tip: Cannot connect to MySQL server.');
      console.error('   - Check if host and port are correct');
      console.error('   - Verify MySQL server is accessible from your network');
    } else if (error.code === 'ER_ACCESS_DENIED_ERROR' || error.errno === 1045) {
      console.error('💡 Tip: Authentication failed.');
      console.error('   - Check your username and password in .env file');
      console.error('   - Verify database user has correct permissions');
    } else if (error.code === 'ER_BAD_DB_ERROR' || error.errno === 1049) {
      console.error('💡 Tip: Database does not exist.');
      console.error('   - Create the database first');
      console.error('   - Or check database name in .env file');
    } else if (error.code === 'ENOTFOUND') {
      console.error('💡 Tip: Cannot resolve hostname.');
      console.error('   - Check DB_HOST in .env file');
      console.error('   - Verify DNS resolution');
    } else if (error.code === 'ETIMEDOUT') {
      console.error('💡 Tip: Connection timed out.');
      console.error('   - Check if MySQL server is accessible');
      console.error('   - Verify firewall settings');
    } else if (error.code && error.code.includes('SSL')) {
      console.error('💡 Tip: SSL/TLS connection issue.');
      console.error('   - Try setting DB_SSL=false in .env file');
      console.error('   - Or configure proper SSL certificates');
    }
    
    console.error('');
    console.error('Full error details:');
    console.error(JSON.stringify(error, Object.getOwnPropertyNames(error), 2));
    console.error('');
    process.exit(1);
  }
}

testConnection();
