#!/bin/bash

# Ubah bind-address di file konfigurasi MySQL
MYSQL_CONFIG_FILE="/etc/mysql/my.cnf"

if [ ! -f "$MYSQL_CONFIG_FILE" ]; then
  MYSQL_CONFIG_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
fi

if [ -f "$MYSQL_CONFIG_FILE" ]; then
  sudo sed -i 's/bind-address\s*=.*127.0.0.1/bind-address = 0.0.0.0/' "$MYSQL_CONFIG_FILE"
  echo "Konfigurasi MySQL diubah: bind-address sekarang 0.0.0.0."
else
  echo "File konfigurasi MySQL tidak ditemukan."
  exit 1
fi

# Restart layanan MySQL untuk menerapkan perubahan
sudo systemctl restart mysql
echo "Layanan MySQL di-restart."

# Membuka port 3306 jika belum terbuka
if sudo ufw status | grep -q "3306.*DENY"; then
  sudo ufw allow 3306
  echo "Port 3306 dibuka di firewall."
else
  echo "Port 3306 sudah terbuka di firewall."
fi

# Login ke MySQL sebagai root dan membuat user 'admindb'
mysql -u root -p -e "
CREATE USER 'admindb'@'%' IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON *.* TO 'admindb'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
"

echo "User 'admindb' dengan akses root telah berhasil dibuat."
