#!/bin/bash

# 1. Mendapatkan versi phpMyAdmin terbaru
export PHPMYADMIN_VERSION=$(curl --silent https://www.phpmyadmin.net/downloads/ | grep "btn btn-success download_popup" | sed -n 's/.*href="\([^"]*\).*/\1/p' | tr '/' '\n' | grep -E '^.*[0-9]+\.[0-9]+\.[0-9]+$')

# 2. Mengunduh dan mengekstrak phpMyAdmin
cd /var/www/pterodactyl/public || exit
wget https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VERSION/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
unzip phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
rm phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
mv phpMyAdmin-$PHPMYADMIN_VERSION-all-languages pma

# 3. Mengubah bind-address pada file konfigurasi MariaDB
sed -i 's/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# 4. Memberikan hak akses pada user 'admindb'
mysql -u root -p -e "GRANT ALL PRIVILEGES ON *.* TO admindb@'%' IDENTIFIED BY 'admin' WITH GRANT OPTION;"

# 5. Merestart layanan MySQL untuk menerapkan perubahan
systemctl restart mysql
