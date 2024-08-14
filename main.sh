#!/bin/bash

# Warna
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Banner
echo -e "${CYAN}############################################################${NC}"
echo -e "${CYAN}#                                                          #${NC}"
echo -e "${CYAN}#                   Welcome to PabloNetwork                #${NC}"
echo -e "${CYAN}#                  PHPMyAdmin Installer Script             #${NC}"
echo -e "${CYAN}#                                                          #${NC}"
echo -e "${CYAN}############################################################${NC}"
echo

# Opsi menu
echo -e "${YELLOW}Choose an option:${NC}"
echo -e "${GREEN}0) Install phpMyAdmin with a domain${NC}"
echo -e "${GREEN}1) Install phpMyAdmin without a domain${NC}"
echo -e "${GREEN}2) Uninstall phpMyAdmin${NC}"
echo -e "${GREEN}3) Cancel or Exit${NC}"
echo
read -p "Enter your choice [0-3]: " choice

# Fungsi untuk menginstal phpMyAdmin dengan domain
install_with_domain() {
    echo -e "${CYAN}Starting installation with domain...${NC}"
    sleep 2

    # Update dan upgrade sistem
    sudo apt update -y
    sudo apt upgrade -y

    # Instalasi Nginx, PHP, dan Certbot
    sudo apt install -y nginx php-fpm php-mysql wget unzip certbot python3-certbot-nginx

    # Unduh phpMyAdmin
    wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip -O /tmp/phpmyadmin.zip

    # Rename dan ekstrak
    sudo unzip /tmp/phpmyadmin.zip -d /usr/share/
    sudo mv /usr/share/phpMyAdmin-5.2.1-all-languages /usr/share/pma

    # Setel hak akses
    sudo chown -R www-data:www-data /usr/share/pma
    sudo chmod -R 755 /usr/share/pma

    # Meminta input domain dari pengguna
    read -p "Please enter your domain: " domain

    # Konfigurasi Nginx
    sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;

    root /var/www/html;
    index index.php index.htm index.nginx-debian.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    # phpMyAdmin configuration
    location /pma {
        alias /usr/share/pma;
        index index.php;
        try_files \$uri \$uri/ =404;
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
            include fastcgi_params;
        }
    }
}
EOF

    # Restart Nginx
    sudo systemctl restart nginx

    # Certbot untuk SSL
    sudo certbot --nginx -d $domain

    # Hapus log instalasi
    rm -rf /var/log/apt/*

    echo -e "${GREEN}phpMyAdmin has been installed and is accessible at https://$domain/pma${NC}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
}

# Fungsi untuk menginstal phpMyAdmin tanpa domain
install_without_domain() {
    echo -e "${CYAN}Starting installation without domain...${NC}"
    sleep 2

    # Update dan upgrade sistem
    sudo apt update -y
    sudo apt upgrade -y

    # Instalasi Nginx, PHP, dan dependensi lainnya
    sudo apt install -y nginx php-fpm php-mysql wget unzip

    # Unduh phpMyAdmin
    wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip -O /tmp/phpmyadmin.zip

    # Rename dan ekstrak
    sudo unzip /tmp/phpmyadmin.zip -d /usr/share/
    sudo mv /usr/share/phpMyAdmin-5.2.1-all-languages /usr/share/pma

    # Setel hak akses
    sudo chown -R www-data:www-data /usr/share/pma
    sudo chmod -R 755 /usr/share/pma

    # Ambil IP publik VPS
    ip_vps=$(curl -s http://checkip.amazonaws.com)

    # Konfigurasi Nginx
    sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $ip_vps;

    root /var/www/html;
    index index.php index.htm index.nginx-debian.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    # phpMyAdmin configuration
    location /pma {
        alias /usr/share/pma;
        index index.php;
        try_files \$uri \$uri/ =404;
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
            include fastcgi_params;
        }
    }
}
EOF

    # Restart Nginx
    sudo systemctl restart nginx

    # Hapus log instalasi
    rm -rf /var/log/apt/*

    echo -e "${GREEN}phpMyAdmin has been installed and is accessible at http://$ip_vps/pma${NC}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
}

# Fungsi untuk menghapus phpMyAdmin
uninstall_phpmyadmin() {
    echo -e "${RED}Uninstalling phpMyAdmin...${NC}"
    sleep 2
    
    # Hapus direktori phpMyAdmin
    sudo rm -rf /usr/share/pma

    # Restart Nginx
    sudo systemctl restart nginx

    echo -e "${GREEN}phpMyAdmin has been removed.${NC}"
}

# Proses berdasarkan pilihan pengguna
case $choice in
    0)
        install_with_domain
        ;;
    1)
        install_without_domain
        ;;
    2)
        uninstall_phpmyadmin
        ;;
    3)
        echo -e "${YELLOW}Installation canceled. Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option selected. Please choose 0, 1, 2, or 3.${NC}"
        ;;
esac

echo -e "${CYAN}############################################################${NC}"
echo -e "${CYAN}#                                                          #${NC}"
echo -e "${CYAN}#            Thank you for using PabloNetwork              #${NC}"
echo -e "${CYAN}#              PHPMyAdmin Installer Script                 #${NC}"
echo -e "${CYAN}#                                                          #${NC}"
echo -e "${CYAN}############################################################${NC}"
