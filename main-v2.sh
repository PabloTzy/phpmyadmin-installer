#!/bin/bash

# Pastikan domain diinput oleh user
read -p "Masukkan domain Anda (contoh: domainanda.com): " domain

# Pilihan HTTPS atau HTTP
echo "Pilih opsi koneksi:"
echo "1. HTTPS (Let's Encrypt)"
echo "2. HTTP (tanpa SSL)"
read -p "Masukkan pilihan Anda [1/2]: " opsi

# Update package lists dan install dependencies
sudo apt update
sudo apt install -y nginx mysql-server php8.1-fpm php8.1-mysql wget unzip

# Install phpMyAdmin
cd /var/www/html
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip
unzip phpMyAdmin-latest-all-languages.zip
mv phpMyAdmin-*-all-languages pma
rm phpMyAdmin-latest-all-languages.zip
sudo chown -R www-data:www-data /var/www/html/pma

# Konfigurasi Nginx berdasarkan pilihan HTTP atau HTTPS
if [ "$opsi" -eq 1 ]; then
    # Install Certbot jika memilih HTTPS
    sudo apt install -y certbot python3-certbot-nginx

    # Konfigurasi Nginx dengan HTTPS
    cat <<EOL | sudo tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    root /var/www/html;
    index index.php;

    location /pma/ {
        alias /var/www/html/pma/;
        index index.php;
        
        location ~ \.php\$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        }

        location ~ /\.ht {
            deny all;
        }
    }

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

    # Aktifkan konfigurasi Nginx dan jalankan Certbot untuk HTTPS
    sudo ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
    sudo certbot --nginx -d $domain --non-interactive --agree-tos --email admin@$domain

elif [ "$opsi" -eq 2 ]; then
    # Konfigurasi Nginx tanpa HTTPS
    cat <<EOL | sudo tee /etc/nginx/sites-available/$domain.conf
server {
    listen 80;
    server_name $domain;

    root /var/www/html;
    index index.php;

    location /pma/ {
        alias /var/www/html/pma/;
        index index.php;
        
        location ~ \.php\$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        }

        location ~ /\.ht {
            deny all;
        }
    }

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

    # Aktifkan konfigurasi Nginx tanpa SSL
    sudo ln -s /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
else
    echo "Pilihan tidak valid, proses dihentikan."
    exit 1
fi

# Konfigurasi MySQL bind address
sudo sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# Membuat user admindb dan admin dengan akses root dan remote
mysql -u root <<MYSQL_SCRIPT
CREATE USER 'admindb'@'%' IDENTIFIED BY 'password_anda';
CREATE USER 'admin'@'%' IDENTIFIED BY 'password_anda';
GRANT ALL PRIVILEGES ON *.* TO 'admindb'@'%' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "phpMyAdmin (di /pma), konfigurasi Nginx, dan MySQL user setup completed!"
