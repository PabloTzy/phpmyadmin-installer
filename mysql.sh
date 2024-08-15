#!/bin/bash

# Define variables
DB_USER="admindb"
DB_PASSWORD="admin"
MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Allow MySQL to listen on all IP addresses
echo "Updating MySQL configuration to listen on all IP addresses..."
if ! grep -q "^bind-address" "$MYSQL_CONF"; then
  echo "bind-address = 0.0.0.0" >> "$MYSQL_CONF"
else
  sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "$MYSQL_CONF"
fi

# Restart MySQL to apply configuration changes
echo "Restarting MySQL service..."
systemctl restart mysql

# Create a MySQL user with root-like privileges
echo "Creating MySQL user '$DB_USER' with root-like privileges..."
mysql -u root -e "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'%' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"

# Display user and password
echo "User '$DB_USER' created with root-like privileges."
echo "You can now access MySQL remotely using the following credentials:"
echo "Username: $DB_USER"
echo "Password: $DB_PASSWORD"

echo "MySQL has been configured to accept connections from external IPs."
