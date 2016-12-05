#!/bin/sh
apk update
apk add curl
source /vagrant/provisions/env.sh

### NGINX ###
apk add nginx

adduser -D -u 1234 -g 'www' www
mkdir /www
chown -R www:www /var/lib/nginx
chown -R www:www /www

mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
cp /vagrant/provisions/nginx.conf /etc/nginx/nginx.conf
rm -rf /etc/nginx/conf.d
cp -pr /vagrant/provisions/nginx/conf.d /etc/nginx/conf.d
chown -R vagrant /etc/nginx/conf.d
ln -s /etc/nginx/conf.d /home/vagrant/site-availables
rc-update add nginx default

### PHP 5x ###
apk add libpng-dev gd-dev gd
apk add php5-fpm \
    php5-mcrypt php5-soap php5-openssl php5-gmp \
    php5-json php5-zip php5-dom \
    php5-pdo php5-mysql php5-mysqli php5-sqlite3 php5-pdo_pgsql \
    php5-odbc php5-pdo_odbc php5-pdo_mysql php5-pdo_sqlite php5-mssql \
    php5-apcu php5-bcmath php5-gd php5-xcache \
    php5-gettext php5-xmlreader php5-xmlrpc php5-xml php5-bz2 \
    php5-memcache php5-iconv php5-pdo_dblib php5-curl php5-ctype \
    php5-pcntl php5-intl php5-zlib php5-ftp php5-phalcon php5-gd

sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php5/php-fpm.conf
sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php5/php-fpm.conf
sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php5/php-fpm.conf
sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php5/php-fpm.conf
sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php5/php-fpm.conf
sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php5/php-fpm.conf

sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php5/php.ini
sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php5/php.ini
sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php5/php.ini
sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php5/php.ini
sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php5/php.ini
sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php5/php.ini
sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php5/php.ini
sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php5/php.ini

apk add tzdata
cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "${TIMEZONE}" > /etc/timezone
sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php5/php.ini

echo "<?php phpinfo();?>" > /www/info.php
rc-service nginx start
rc-service php-fpm start
rc-update add php-fpm default

### MARIA DB ###
apk add mariadb mariadb-client

mysql_install_db --user=mysql --datadir=${MYSQL_DATA_PATH}
rc-service mariadb start
mysqladmin -u root password "${MYSQL_ROOT_PASS}"

echo "GRANT ALL ON *.* TO ${MYSQL_USER}@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASS}' WITH GRANT OPTION;" > /tmp/sql
echo "GRANT ALL ON *.* TO ${MYSQL_USER}@'localhost' IDENTIFIED BY '${MYSQL_PASS}' WITH GRANT OPTION;" >> /tmp/sql
echo "GRANT ALL ON *.* TO ${MYSQL_USER}@'::1' IDENTIFIED BY '${MYSQL_PASS}' WITH GRANT OPTION;" >> /tmp/sql
echo "DELETE FROM mysql.user WHERE User='';" >> /tmp/sql
echo "DROP DATABASE test;" >> /tmp/sql
echo "FLUSH PRIVILEGES;" >> /tmp/sql
cat /tmp/sql | mysql -u root --password='${MYSQL_ROOT_PASS}'

sed -i "s|max_allowed_packet\s*=\s*1M|max_allowed_packet = ${MYSQL_MAX_ALLOWED_PACKET}|g" /etc/mysql/my.cnf
sed -i "s|max_allowed_packet\s*=\s*16M|max_allowed_packet = ${MYSQL_MAX_ALLOWED_PACKET}|g" /etc/mysql/my.cnf

rc-update add mariadb default

### phpMyAdmin ###
curl -O https://files.phpmyadmin.net/phpMyAdmin/4.0.10.18/phpMyAdmin-4.0.10.18-english.zip
unzip phpMyAdmin-4.0.10.18-english.zip && rm -rf phpMyAdmin-4.0.10.18-english.zip
mv phpMyAdmin-4.0.10.18-english phpmyadmin
cd phpmyadmin
cp config.sample.inc.php config.inc.php

sed -i "s|cfg\['blowfish_secret'\]\s*=\s*'a8b7c6d';|cfg['blowfish_secret'] = '${PHPMYADMIN_BLOWFISH_SECRET}';|g" config.inc.php
