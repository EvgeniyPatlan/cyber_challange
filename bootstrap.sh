#!/bin/bash

# Install Percona Server for MySQL 5.7
yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
percona-release setup ps57
yum install -y Percona-Server-server-57

cat <<EOF > /etc/my.cnf
[mysqld]
pid-file=/var/run/mysqld/mysqld.pid
log-error=/var/log/mysqld.log
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
symbolic-links=0


[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

!includedir /etc/my.cnf.d
EOF

service mysqld start
PASS=$(grep "temporary password" /var/log/mysqld.log | awk '{print $NF}')
mysql -u root -p${PASS} -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass%123';FLUSH PRIVILEGES;" --connect-expired-password
NEW_PASS='MyNewPass%123'
mysql -u root -p${NEW_PASS} -e "create database students-competition;" --connect-expired-password


#install web part
yum install -y wget git vim unzip
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php82
yum install -y php openssl php-fpm php-bcmath php-common php-curl php-json php-mbstring php-mysql php-xml php-zip
#install composer
wget https://raw.githubusercontent.com/composer/getcomposer.org/76a7060ccb93902cd7576b67264ad91c8a2700e2/web/installer -O - -q | php -- --quiet
mv composer.phar /usr/local/bin/composer
ln -s /usr/local/bin/composer /usr/bin/composer


# Install Nginx
yum install -y epel-release
yum install -y nginx

# Start and enable Nginx
systemctl start nginx
systemctl enable nginx
mkdir /etc/nginx/sites-enabled/
mkdir /etc/nginx/sites-available/

# Create user 'admin' with specified password
useradd admin
echo "admin:password" | chpasswd


# Setup firewall
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-port=2024/tcp --permanent
firewall-cmd --reload
sudo setenforce 0
# Configure SSH to listen on specified ports
echo -e "Port 22\nPort 2222\nPort 2000\nPort 2024\nPort 2022\nPort 1022" >> /etc/ssh/sshd_config
# Restart SSHD to apply configuration

cat <<EOF > /etc/ssh/sshd_config
Port 22
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

AuthorizedKeysFile      .ssh/authorized_keys

PasswordAuthentication yes
ChallengeResponseAuthentication no
GSSAPIAuthentication yes
GSSAPICleanupCredentials no
UsePAM yes

UseDNS no
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS

# override default of no subsystems
Subsystem       sftp    /usr/libexec/openssh/sftp-server

Port 22
Port 2222
Port 2000
Port 2024
Port 2022
Port 1022

EOF

systemctl restart sshd

# Setup cron job for 'admin' that does nothing
echo "* * * * * /home/admin/cron.sh" > /var/spool/cron/admin
# Create a script in 'admin's home directory for the cron job
echo "#!/bin/bash" > /home/admin/cron.sh
echo "# This script does nothing" >> /home/admin/cron.sh
chmod +x /home/admin/cron.sh
chown admin:admin /home/admin/cron.sh


#configure php app
cd /var/www/
git clone https://github.com/olexandrpolosmak/test-admin.git
chmod -R 777 test-admin
cd test-admin
mv nginx.conf /etc/nginx/
mv upstream.conf /etc/nginx/conf.d/
rm -f /etc/nginx/nginx.conf.default
service nginx stop
service nginx start
cp test-admin.conf /etc/nginx/sites-available/test-admin.conf
ln -s /etc/nginx/sites-available/test-admin.conf /etc/nginx/sites-enabled/test-admin.conf
composer install
cp .env.example .env
sed -i 's:DB_PASSWORD=:DB_PASSWORD=MyNewPass%123:' .env
#sed -i 's|APP_URL=http://localhost|APP_URL=http://students-competition.test|' .env
sed -i 's:DB_DATABASE=:DB_DATABASE=students-competition:' .env
php artisan key:generate
php artisan migrate --force
php artisan init:app 12345678
mkdir -p /run/php-fpm/
php-fpm
service nginx stop
service nginx start
