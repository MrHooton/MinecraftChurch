# Database Configuration for Denizen MySQL Connection
# Apex MySQL Hosting Configuration

database_config:
  type: data
  mysql_host: "mysql.apexhosting.gdn"
  mysql_port: "3306"
  mysql_database: "apexMC2969109"
  mysql_username: "apexMC2969109"
  
  # Server format for Denizen SQL connect command: host:port/database
  # Note: Build server string to avoid colon escaping issues
  mysql_server: "mysql.apexhosting.gdn:3306/apexMC2969109"
  
  # Password secret name (stored in plugins/Denizen/secrets.secret)
  mysql_password_secret: "mysql_password"