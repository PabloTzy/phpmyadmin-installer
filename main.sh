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
echo -e "${GREEN}1) Install phpMyAdmin with a domain behind Cloudflare proxy${NC}"
echo -e "${GREEN}2) Install phpMyAdmin without a domain${NC}"
echo -e "${GREEN}3) Install phpMyAdmin and MySQL with a domain${NC}"
echo -e "${GREEN}4) Install phpMyAdmin and MySQL with a domain behind Cloudflare proxy${NC}"
echo -e "${GREEN}5) Install phpMyAdmin and MySQL without a domain${NC}"
echo -e "${GREEN}6) Remove Cloudflare proxy settings${NC}"
echo -e "${GREEN}7) Uninstall phpMyAdmin${NC}"
echo -e "${GREEN}8) Cancel or Exit${NC}"
echo
read -p "Enter your choice [0-8]: " choice

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
        rewrite ^/$ /pma permanent;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
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
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
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
        rewrite ^/$ /pma permanent;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
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
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
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

# Fungsi untuk menginstal phpMyAdmin dan MySQL dengan domain
install_with_mysql_domain() {
    echo -e "${CYAN}Starting installation with domain...${NC}"
    sleep 2

    # Update dan upgrade sistem
    sudo apt update -y
    sudo apt upgrade -y

    # Instalasi Nginx, PHP, MySQL, dan Certbot
    sudo apt install -y nginx php-fpm php-mysql mysql-server wget unzip certbot python3-certbot-nginx

    # Amankan MySQL
    sudo mysql_secure_installation

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
        rewrite ^/$ /pma permanent;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
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
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
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

    echo -e "${GREEN}phpMyAdmin and MySQL have been installed and are accessible at https://$domain/pma${NC}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
}

# Fungsi untuk menginstal phpMyAdmin dan MySQL tanpa domain
install_without_mysql_domain() {
    echo -e "${CYAN}Starting installation without domain...${NC}"
    sleep 2

    # Update dan upgrade sistem
    sudo apt update -y
    sudo apt upgrade -y

    # Instalasi Nginx, PHP, MySQL, dan dependensi lainnya
    sudo apt install -y nginx php-fpm php-mysql mysql-server wget unzip

    # Amankan MySQL
    sudo mysql_secure_installation

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
        rewrite ^/$ /pma permanent;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
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
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
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

    echo -e "${GREEN}phpMyAdmin and MySQL have been installed and are accessible at http://$ip_vps/pma${NC}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
}

# Fungsi untuk menghapus phpMyAdmin
uninstall_phpmyadmin() {
    echo -e "${CYAN}Starting uninstallation of phpMyAdmin...${NC}"
    sleep 2

    # Hapus phpMyAdmin dan file terkait
    sudo rm -rf /usr/share/pma
    sudo rm /etc/nginx/sites-available/default
    sudo rm /etc/nginx/sites-enabled/default

    # Restart Nginx
    sudo systemctl restart nginx

    echo -e "${GREEN}phpMyAdmin has been uninstalled successfully!${NC}"
}

# Fungsi untuk menginstal phpMyAdmin dengan domain dan Cloudflare proxy
install_with_domain_cf_proxy() {
    echo -e "${CYAN}Starting installation with domain and Cloudflare proxy...${NC}"
    sleep 2

    # Lakukan langkah-langkah yang diperlukan seperti pada fungsi install_with_domain
    install_with_domain

    # Konfigurasi tambahan untuk Cloudflare proxy
    sudo tee -a /etc/nginx/sites-available/default > /dev/null <<EOF

# Cloudflare Proxy Configuration
set_real_ip_from 173.245.48.0/20;
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 104.16.0.0/12;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 131.0.72.0/22;
real_ip_header CF-Connecting-IP;
EOF

    # Restart Nginx untuk menerapkan perubahan
    sudo systemctl restart nginx

    echo -e "${GREEN}phpMyAdmin with Cloudflare proxy has been installed and is accessible at https://$domain/pma${NC}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
}

# Fungsi untuk menginstal phpMyAdmin dan MySQL dengan domain dan Cloudflare proxy
install_with_mysql_domain_cf_proxy() {
    echo -e "${CYAN}Starting installation with domain, MySQL, and Cloudflare proxy...${NC}"
    sleep 2

    # Lakukan langkah-langkah yang diperlukan seperti pada fungsi install_with_mysql_domain
    install_with_mysql_domain

    # Konfigurasi tambahan untuk Cloudflare proxy
    sudo tee -a /etc/nginx/sites-available/default > /dev/null <<EOF

# Cloudflare Proxy Configuration
set_real_ip_from 173.245.48.0/20;
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 104.16.0.0/12;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 131.0.72.0/22;
real_ip_header CF-Connecting-IP;
EOF

    # Restart Nginx untuk menerapkan perubahan
    sudo systemctl restart nginx

    echo -e "${GREEN}phpMyAdmin with MySQL and Cloudflare proxy has been installed and is accessible at https://$domain/pma${NC}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
}

# Fungsi untuk menghapus pengaturan proxy Cloudflare
remove_cf_proxy() {
    echo -e "${CYAN}Removing Cloudflare proxy settings...${NC}"
    sleep 2

    # Hapus konfigurasi tambahan untuk Cloudflare proxy
    sudo sed -i '/# Cloudflare Proxy Configuration/,+18d' /etc/nginx/sites-available/default

    # Restart Nginx untuk menerapkan perubahan
    sudo systemctl restart nginx

    echo -e "${GREEN}Cloudflare proxy settings have been removed!${NC}"
}

# Pilihan menu
case $choice in
    0)
        install_with_domain
        ;;
    1)
        install_with_domain_cf_proxy
        ;;
    2)
        install_without_domain
        ;;
    3)
        install_with_mysql_domain
        ;;
    4)
        install_with_mysql_domain_cf_proxy
        ;;
    5)
        install_without_mysql_domain
        ;;
    6)
        remove_cf_proxy
        ;;
    7)
        uninstall_phpmyadmin
        ;;
    8)
        echo -e "${YELLOW}Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option! Please choose a valid option.${NC}"
        ;;
esac
