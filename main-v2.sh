#!/bin/bash

# Pastikan dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    echo "Mohon jalankan skrip ini sebagai root."
    exit 1
fi

# Menu pilihan operasi
echo "======================================"
echo "Skrip Install/Uninstall phpMyAdmin"
echo "======================================"
echo "1. Install phpMyAdmin"
echo "2. Uninstall phpMyAdmin"
echo "======================================"
read -p "Pilih operasi [1/2]: " operasi

# Fungsi untuk menginstal phpMyAdmin
install_phpmyadmin() {
    # Input domain
    read -p "Masukkan domain Anda (contoh: domainanda.com): " domain

    if [ -z "$domain" ]; then
        echo "Domain tidak boleh kosong. Proses dihentikan."
        exit 1
    fi

    # Pilihan HTTPS atau HTTP
    echo "Pilih opsi koneksi:"
    echo "1. HTTPS (Let's Encrypt)"
    echo "2. HTTP (tanpa SSL)"
    read -p "Masukkan pilihan Anda [1/2]: " opsi

    # Update dan install dependencies
    apt update
    apt install -y php8.1-fpm wget unzip nginx certbot python3-certbot-nginx

    # Unduh dan instal phpMyAdmin
    mkdir -p /var/www/phpmyadmin/tmp && cd /var/www/phpmyadmin
    wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
    tar xvzf phpMyAdmin-latest-english.tar.gz
    mv phpMyAdmin-*-english/* /var/www/phpmyadmin
    rm -rf phpMyAdmin-latest-english*

    # Ubah izin direktori
    chown -R www-data:www-data /var/www/phpmyadmin
    mkdir /var/www/phpmyadmin/config
    chmod o+rw /var/www/phpmyadmin/config

    # Konfigurasi Nginx
    if [ "$opsi" -eq 1 ]; then
        # HTTPS
        cat <<EOL > /etc/nginx/sites-available/phpmyadmin.conf
server {
    listen 80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    root /var/www/phpmyadmin;
    index index.php;

    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOL
        # Install SSL
        certbot --nginx -d $domain --non-interactive --agree-tos --email admin@$domain
    elif [ "$opsi" -eq 2 ]; then
        # HTTP
        cat <<EOL > /etc/nginx/sites-available/phpmyadmin.conf
server {
    listen 80;
    server_name $domain;

    root /var/www/phpmyadmin;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOL
    else
        echo "Pilihan tidak valid. Proses dihentikan."
        exit 1
    fi

    ln -s /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/
    systemctl restart nginx

    echo "phpMyAdmin berhasil diinstal untuk domain $domain."
}

# Fungsi untuk menghapus phpMyAdmin
uninstall_phpmyadmin() {
    read -p "Masukkan domain Anda (contoh: domainanda.com): " domain

    if [ -z "$domain" ]; then
        echo "Domain tidak boleh kosong. Proses dihentikan."
        exit 1
    fi

    echo "Menghapus konfigurasi phpMyAdmin untuk domain: $domain..."

    # Hapus direktori phpMyAdmin
    if [ -d "/var/www/phpmyadmin" ]; then
        rm -rf /var/www/phpmyadmin
        echo "Direktori /var/www/phpmyadmin berhasil dihapus."
    else
        echo "Direktori /var/www/phpmyadmin tidak ditemukan."
    fi

    # Hapus konfigurasi Nginx
    if [ -f "/etc/nginx/sites-available/phpmyadmin.conf" ]; then
        rm -f /etc/nginx/sites-available/phpmyadmin.conf
        rm -f "/etc/nginx/sites-enabled/phpmyadmin.conf"
        echo "Konfigurasi Nginx untuk phpMyAdmin berhasil dihapus."
    fi

    # Restart Nginx
    systemctl restart nginx

    # Hapus sertifikat SSL
    if [ -d "/etc/letsencrypt/live/$domain" ]; then
        certbot delete --cert-name "$domain"
        echo "Sertifikat SSL untuk domain $domain berhasil dihapus."
    else
        echo "Sertifikat SSL untuk domain $domain tidak ditemukan."
    fi

    # Hapus paket-paket
    read -p "Apakah Anda ingin menghapus paket phpMyAdmin dan dependencies? [y/n]: " hapus_paket
    if [[ "$hapus_paket" == "y" || "$hapus_paket" == "Y" ]]; then
        apt purge -y phpmyadmin php8.1-fpm wget unzip
        apt autoremove -y
        echo "Paket phpMyAdmin dan dependencies berhasil dihapus."
    else
        echo "Paket phpMyAdmin tidak dihapus."
    fi

    echo "phpMyAdmin berhasil dihapus dari server."
}

# Eksekusi pilihan operasi
case "$operasi" in
    1)
        install_phpmyadmin
        ;;
    2)
        uninstall_phpmyadmin
        ;;
    *)
        echo "Pilihan tidak valid. Proses dihentikan."
        exit 1
        ;;
esac
