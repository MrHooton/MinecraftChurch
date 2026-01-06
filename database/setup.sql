-- Minecraft Church Server: Database Setup Script
-- Run this script to create the database and apply the schema

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS minecraft_church 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Use the database
USE minecraft_church;

-- Apply the schema
SOURCE schema.sql;

-- Verify tables were created
SHOW TABLES;

-- Display table structures
DESCRIBE verification_codes;
DESCRIBE verification_requests;
DESCRIBE access_grants;
DESCRIBE known_players;
DESCRIBE audit_log;
