#!/bin/bash

# Fungsi untuk menginstal phpMyAdmin
install_phpmyadmin() {
    # Meminta input domain
    read -p "Masukkan domain untuk phpMyAdmin: " DOMAIN

    # Instalasi phpMyAdmin
    echo "Menginstall phpMyAdmin..."
    mkdir /var/www/phpmyadmin && mkdir /var/www/phpmyadmin/tmp/ && cd /var/www/phpmyadmin
    wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
    tar xvzf phpMyAdmin-latest-english.tar.gz
    mv /var/www/phpmyadmin/phpMyAdmin-*-english/* /var/www/phpmyadmin
    chown -R www-data:www-data *
    mkdir config
    chmod o+rw config
    cp config.sample.inc.php config/config.inc.php
    chmod o+w config/config.inc.php

    # Instalasi Certbot dan sertifikat SSL
    echo "Menginstal Certbot dan mengatur SSL untuk domain..."
    apt update && apt install -y certbot python3-certbot-nginx
    certbot certonly --standalone -d $DOMAIN
    1

    # Konfigurasi Nginx
    echo "Membuat konfigurasi Nginx..."
    cat > /etc/nginx/sites-available/phpmyadmin.conf <<EOL
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    root /var/www/phpmyadmin;
    index index.php;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
    ssl_prefer_server_ciphers on;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

    # Mengaktifkan konfigurasi dan restart Nginx
    sudo ln -s /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
    

    # Membersihkan direktori config
    cp /var/www/phpmyadmin/config/config.inc.php /var/www/phpmyadmin
    rm -rf /var/www/phpmyadmin/config
    rm -rf /var/www/phpmyadmin/setup

    echo "Instalasi phpMyAdmin selesai. Akses di https://$DOMAIN"
}

# Fungsi untuk menghapus phpMyAdmin
uninstall_phpmyadmin() {
    echo "Menghapus phpMyAdmin..."
    rm -rf /var/www/phpmyadmin
    rm -f /etc/nginx/sites-available/phpmyadmin.conf
    rm -f /etc/nginx/sites-enabled/phpmyadmin.conf
    systemctl restart nginx
    echo "phpMyAdmin berhasil dihapus."
}

# Menu utama
echo "Pilih opsi:"
echo "1. Install phpMyAdmin"
echo "2. Uninstall phpMyAdmin"
read -p "Masukkan pilihan (1/2): " CHOICE

case $CHOICE in
    1)
        install_phpmyadmin
        ;;
    2)
        uninstall_phpmyadmin
        ;;
    *)
        echo "Pilihan tidak valid."
        ;;
esac
