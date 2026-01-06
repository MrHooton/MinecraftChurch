/**
 * Database Connection Pool Module
 * Manages MySQL connection pool for the API
 */

const mysql = require('mysql2/promise');
const config = require('./config.js');

// Create connection pool
const pool = mysql.createPool({
  host: config.database.host,
  port: config.database.port,
  database: config.database.database,
  user: config.database.user,
  password: config.database.password,
  connectionLimit: config.database.connectionLimit,
  connectionTimeout: config.database.connectionTimeout,
  queueLimit: config.database.queueLimit,
  timezone: config.database.timezone,
  charset: config.database.charset,
  ssl: config.database.ssl
});

/**
 * Test database connection
 */
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    return true;
  } catch (error) {
    console.error('Database connection test failed:', error.message);
    return false;
  }
}

/**
 * Execute a query with error handling
 */
async function query(sql, params = []) {
  try {
    const [results] = await pool.execute(sql, params);
    return results;
  } catch (error) {
    console.error('Database query error:', error.message);
    throw error;
  }
}

/**
 * Get a connection from the pool (for transactions)
 */
async function getConnection() {
  return await pool.getConnection();
}

module.exports = {
  pool,
  query,
  getConnection,
  testConnection
};
