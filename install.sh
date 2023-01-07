#!/bin/bash
# Install nextcloud
# https://upcloud.com/resources/tutorials/install-nextcloud-centos

ADMIN_USER="root"
ADMIN_PASSWORD="root"

DATABASE_ROOT_PASSWORD="root"
DATABASE_NAME="nextcloud"
DATABASE_USER="nextcloud"
DATABASE_PASSWORD="nextcloud"

NEXTCLOUD_RELEASE="https://download.nextcloud.com/server/releases/latest.tar.bz2"
NEXTCLOUD_RELEASE_SHA256="https://download.nextcloud.com/server/releases/latest.tar.bz2.sha256"
NEXTCLOUD_RELEASE_SIG="https://download.nextcloud.com/server/releases/latest.tar.bz2.asc"
NEXTCLOUD_GPG_KEY="https://nextcloud.com/nextcloud.asc"

download_and_check_release () {
  echo "Downloading release"
  wget -c -q --show-progress -O latest.tar.bz2 $NEXTCLOUD_RELEASE
  wget -c -q --show-progress -O latest.tar.bz2.sha256 $NEXTCLOUD_RELEASE_SHA256
  wget -c -q --show-progress -O latest.tar.bz2.asc $NEXTCLOUD_RELEASE_SIG

  # Sha256sum is from coreutils, should be installed (cf. preseed file)
  echo "Checking release integrity"
  sha256sum -c latest.tar.bz2.sha256 < latest.tar.bz2

  if [ $? -ne 0 ]
  then
    echo "Problem with release integrity (sha256sum)."
    exit 1
  fi

  if ! command -v gpg &>/dev/null
  then
    echo "Installing gpg"
    apt-get update &>/dev/null
    apt-get install -y gpg &>/dev/null
  fi

  gpg --keyserver pgp.mit.edu --recv-keys 28806A878AE423A28372792ED75899B9A724937A
  gpg --keyserver pgp.mit.edu --recv-keys 28806A878AE423A28372792ED75899B9A724937A
  gpg --verify latest.tar.bz2.asc latest.tar.bz2
  
  if [ $? -eq 0 ]
  then
    echo "Release Verified"
  else
    echo "Problem with release signature."
    exit 1
  fi
}
remove_release_artefact () {
  rm -f latest.tar.bz2
  rm -f latest.tar.bz2.asc
  rm -f latest.tar.bz2.sha256
  echo "Artefact Removed"
}
full_upgrade_system () {
  apt-get update
  apt full-upgrade -y
}
install_apache () {
  apt-get install -y apache2
  cat << EOF > /etc/apache2/sites-available/nextcloud.conf
<VirtualHost *:80>
  DocumentRoot /var/www/nextcloud/
  ServerName  $(dnsdomainname --fqdn)

  <Directory /var/www/nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
</VirtualHost>
EOF
  a2dissite 000-default.conf
  a2ensite nextcloud.conf
  
  a2enmod rewrite

  a2enmod headers
  a2enmod env
  a2enmod dir
  a2enmod mime

  systemctl restart apache2
}
install_php () {
  apt-get install -y php-fpm php-gd php-mysql \
    php-curl php-mbstring php-intl php-gmp php-bcmath php-xml php-imagick php-zip

  # Enable Php-fpm
  a2enmod proxy_fcgi setenvif
  a2enconf php7.4-fpm

  systemctl restart apache2

  cat << EOF > /etc/php/7.4/fpm/pool.d/www.conf
[www]
user = www-data
group = www-data

listen = /run/php/php7.4-fpm.sock
listen.owner = www-data
listen.group = www-data

pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 10s
pm.max_requests = 200

; Install request ? Auto install ?
; request_terminate_timeout = 10s

; Chroot to this directory at the start. This value must be defined as an
; absolute path. When this value is not set, chroot is not used.
; Note: you can prefix with '\$prefix' to chroot to the pool prefix or one
; of its subdirectories. If the pool prefix is not set, the global prefix
; will be used instead.
; Note: chrooting is a great security feature and should be used whenever
;       possible. However, all PHP paths will be relative to the chroot
;       (error_log, sessions.save_path, ...).
; Default Value: not set
;chroot =

; Chdir to this directory at the start.
; Note: relative path can be used.
; Default Value: current directory or / when chroot
;chdir = /var/www

env[HOSTNAME] = \$HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp

php_admin_value[memory_limit] = 512M
EOF
  systemctl enable php7.4-fpm
  systemctl start php7.4-fpm
}

install_mariadb () {
  echo "Installing and configuring mariadb"
  apt-get install -y mariadb-server &>/dev/null
  
  echo -e "\ny\ny\n$DATABASE_ROOT_PASSWORD\n$DATABASE_ROOT_PASSWORD\ny\ny\ny\ny" \
  | mysql_secure_installation &>/dev/null

  mysql -u root -p=$DATABASE_ROOT_PASSWORD << EOF
  -- https://stackoverflow.com/questions/35392733/mysql-create-user-if-not-exists
  DROP USER IF EXISTS '$DATABASE_USER'@'localhost';

  CREATE USER '$DATABASE_USER'@'localhost' IDENTIFIED BY '$DATABASE_PASSWORD';
  CREATE DATABASE IF NOT EXISTS $DATABASE_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
  GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@'localhost';
  FLUSH PRIVILEGES;
EOF
  echo "Mariadb installed and configured"
}

install_redis () {
  echo "Installing Redis" 
}

install_nextcloud () {
  tar -xvf latest.tar.bz2
  #   "directory"     => "/var/www/nextcloud/data",
  cat << EOF > nextcloud/config/autoconfig.php
<?php
\$AUTOCONFIG = array(
  "dbtype"        => "mysql",
  "dbname"        => "$DATABASE_NAME",
  "dbuser"        => "$DATABASE_USER",
  "dbpass"        => "$DATABASE_PASSWORD",
  "dbhost"        => "localhost",
  "dbtableprefix" => "",
  "adminlogin"    => "$ADMIN_USER",
  "adminpass"     => "$ADMIN_PASSWORD",
);
EOF

  rm -rf /var/www/html

  cp -r nextcloud /var/www/

  chown -R www-data:www-data /var/www/nextcloud/
  chmod -R 755 /var/www/nextcloud/

}

install_cloudflare_tunnel () {
  wget -c -q --show-progress https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
  dpkg -i cloudflared-linux-amd64.deb


  exit
  cloudflare tunnel login
  cloudflared tunnel create nextcloud
}
# download_and_check_release
# full_upgrade_system
# install_mariadb
# install_apache
# install_php
# install_nextcloud
# install_cloudflare_tunnel
# remove_release_artefact

