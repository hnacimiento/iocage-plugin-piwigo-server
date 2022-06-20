#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf nginx_enable="YES"
sysrc -f /etc/rc.conf mysql_enable="YES"
sysrc -f /etc/rc.conf php_fpm_enable="YES"
# Start the service
service nginx start 2>/dev/null
service php-fpm start 2>/dev/null
service mysql-server start 2>/dev/null

# Create user 'piwigo'
pw user add -n piwigo -s /sbin/nologin -c "Piwigo"
# Copy a base MySQL configuration to use
# cp /usr/local/etc/mysql/my-small.cnf /usr/local/etc/mysql/my.cnf
# Configure the default PHP settings
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

# Modify settings in php.ini for Piwigo best performance
sed -i '' 's/.*max_execution_time = .*/max_execution_time = 300/' /usr/local/etc/php.ini
sed -i '' 's/.*max_input_time = .*/max_input_time = 300/' /usr/local/etc/php.ini
sed -i '' 's/.*post_max_size = .*/post_max_size = 100M/' /usr/local/etc/php.ini
sed -i '' 's/.*upload_max_filesize = .*/upload_max_filesize=100M/' /usr/local/etc/php.ini
# recommended value of 512MB for php memory limit (avoid warning)
sed -i '' 's/.*memory_limit = .*/memory_limit = 512M/' /usr/local/etc/php.ini
sed -i '' 's/.*;date.timezone =.*/date.timezone = "Europe\/London"/' /usr/local/etc/php.ini

# Create a configuration directory to make managing individual server blocks easier
mkdir /usr/local/etc/nginx/conf.d
mkdir /usr/local/etc/php-fpm.d
# Editing WWW config file - www.conf
grep -qxF 'request_terminate_timeout = 300' /usr/local/etc/php-fpm.d/www.conf || echo 'request_terminate_timeout = 300' >> /usr/local/etc/php-fpm.d/www.conf
# Editing PHP-FPM config file - php-fpm.conf
grep -qxF 'include=/usr/local/etc/php-fpm.d/*.conf' /usr/local/etc/php-fpm.conf || echo 'include=/usr/local/etc/php-fpm.d/*.conf' >> /usr/local/etc/php-fpm.conf

# Create user and database for Piwigo with unique password
USER="piwigouser"
DB="piwigodb"
# Save the config values
echo "$DB" > /root/dbname
echo "$USER" > /root/dbuser
export LC_ALL=C
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/dbpassword
PASS=`cat /root/dbpassword`
echo "Database User: $USER"
echo "Database Password: $PASS"
if [ -e "/root/.mysql_secret" ] ; then
   # Mysql > 57 sets a default PW on root
   TMPPW=$(cat /root/.mysql_secret | grep -v "^#")
   echo "SQL Temp Password: $TMPPW"
# Configure mysql db
echo "ROOT Temp Password: $TMPPW"
mysql -u root -p"${TMPPW}" --connect-expired-password <<-EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${PASS}';
CREATE DATABASE ${DB} CHARACTER SET utf8;
CREATE USER '${USER}'@'localhost' IDENTIFIED BY '${PASS}';
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

else

# Mysql <= 56 does not
# Configure mysql
mysql -u root <<-EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$TMPPW';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';

CREATE DATABASE ${DB} CHARACTER SET utf8;
CREATE USER '${USER}'@'localhost' IDENTIFIED BY '${PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
fi

# Download Piwigo lastet version and unzip
cd /usr/local/www
curl -s -o piwigo.zip "http://piwigo.org/download/dlcounter.php?code=latest"
unzip piwigo.zip && rm -f piwigo.zip

# Change the ownership of the whole Piwigo directory
chown -R piwigo:www /usr/local/www/piwigo

# Completing parameters for the installation wizard
sed -i -e "/_POST\['dbhost'\] : /s/'localhost'/'127.0.0.1'/" /usr/local/www/piwigo/install.php
sed -i -e "/_POST\['dbuser'\] : /s/''/'$USER'/" /usr/local/www/piwigo/install.php
sed -i -e "/_POST\['dbname'\] : /s/''/'$DB'/" /usr/local/www/piwigo/install.php
sed -i -e "/\['user password given by your host provider'\] =/s/'user password supplied by your host provider'/'user password supplied by <b>\/root\/PLUGIN_INFO<\/b>'/" /usr/local/www/piwigo/language/en_GB/install.lang.php
sed -i -e "/\['user password given by your host provider'\] =/s/'user password supplied by your host provider'/'user password supplied by <b>\/root\/PLUGIN_INFO<\/b>'/" /usr/local/www/piwigo/language/en_UK/install.lang.php
sed -i -e "/\['user password given by your host provider'\] =/s/'El proporcionado por su alojador web'/'El proporcionado en <b>\/root\/PLUGIN_INFO<\/b>'/" /usr/local/www/piwigo/language/es_ES/install.lang.php
sed -i -e "/\['user password given by your host provider'\] =/s/'senha de usuário fornecida pelo seu provedor de hospedagem'/'senha de usuário fornecida em <b>\/root\/PLUGIN_INFO<\/b>'/" /usr/local/www/piwigo/language/pt_BR/install.lang.php

# Restart the services to make sure we have pick up the new permission
service php-fpm restart 2>/dev/null
# nginx restarts to fast while php is not fully started yet
sleep 5
service nginx restart 2>/dev/null

# Add plugin details to info file available in TrueNAS Plugin Additional Info
echo "Host: 127.0.0.1" > /root/PLUGIN_INFO
echo "Database User: $USER" >> /root/PLUGIN_INFO
echo "Database Password: $PASS" >> /root/PLUGIN_INFO
echo "Database Name: $DB" >> /root/PLUGIN_INFO
