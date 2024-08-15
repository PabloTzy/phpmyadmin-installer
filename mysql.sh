#!/bin/bash

# Define variables
DB_USER="admindb"
DB_PASSWORD="admin"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Create a MySQL user with root-like privileges
mysql -u root -e "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'%' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"

echo "User '$DB_USER' created with root-like privileges."
