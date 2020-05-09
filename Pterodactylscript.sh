#!/bin/bash
# Github.com/AspectDevelopment
function output() {
  echo -e '\e[93m'$1'\e[0m'; #Gele Tekst :3
}

function installchoice {
  output "Dit installatiescript is alleen bedoeld voor gebruik op nieuwe OS-installaties. Installeren op een niet-nieuw besturingssysteem kan dingen kapot maken."
  output "Selecteer nu wat je wilt installeren:\n[1] Installeer het panel.\n[2] Installeer de daemon.\n[3] Installeer en het panel en de deamon."
  read choice
  case $choice in
      1 ) installoption=1
          output "Jij hebt alleen het panel geselecteerd om te installeren."
          ;;
      2 ) installoption=2
          output "Jij hebt alleen de deamon geselecteerd om te installeren."
          ;;
      3 ) installoption=3
          output "Je hebt gekozen om het panel en de deamon te installeren."
          ;;
      * ) output "Oeps, je hebt een verkeerd nummer ingevoerd!"
          installchoice
  esac
}

function webserverchoice {
  output "Welke webserver wil je gebruiken?:\n[1] nginx.\n[2] apache."
  read choice
  case $choice in
      1 ) webserver=1
          output "Je hebt nginx geselecteerd."
          ;;
      2 ) webserver=2
          output "Je hebt apache geselecteerd."
          ;;
      * ) output "Oeps, je hebt een verkeerd nummer ingevoerd!"
          webserverchoice
  esac
}

function required_vars_panel {
    output "Voer hier je FQDN in:"
    read FQDN

    output "Voer je gewenste tijdzone in een PHP formaat:"
    read timezone

    output "Voer hier je eerste naam in:"
    read firstname

    output "Voer hier je achternaam in:"
    read lastname

    output "Voeg hier je username in:"
    read username

    output "Voer hier je email in:"
    read email

    output "Voer hier je wachtwoord in:"
    read userpassword
}

function required_vars_daemon {
  output "Voer je FQDN in!"
  read FQDN
}

function install_apache_dependencies {
  output "Installeren van apache dependencies"
  add-apt-repository -y ppa:ondrej/php
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

  apt update

  apt-get -y install php7.1 php7.1-cli php7.1-gd php7.1-mysql php7.1-pdo php7.1-mbstring php7.1-tokenizer php7.1-bcmath php7.1-xml php7.1-curl php7.1-memcached php7.1-zip mariadb-server libapache2-mod-php apache2 curl tar unzip git memcached
}

function install_nginx_dependencies {
  output "Installeren van dependencies"
  add-apt-repository -y ppa:ondrej/php
  curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

  apt update

  apt-get -y install php7.1 php7.1-cli php7.1-gd php7.1-mysql php7.1-pdo php7.1-mbstring php7.1-tokenizer php7.1-bcmath php7.1-xml php7.1-fpm php7.1-memcached php7.1-curl php7.1-zip mariadb-server nginx curl tar unzip git memcached
}

function panel_downloading {
  output "Downloaden van het panel!"
  mkdir -p /var/www/html/pterodactyl
  cd /var/www/html/pterodactyl

  curl -Lo v0.6.4.tar.gz https://github.com/Pterodactyl/Panel/archive/v0.6.4.tar.gz
  tar --strip-components=1 -xzvf v0.6.4.tar.gz

  chmod -R 755 storage/* bootstrap/cache
}

function panel_installing {
  output "Installeren van het panel!"
  curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

  cp .env.example .env
  composer install --no-dev
  php artisan key:generate --force

  password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

  Q1="CREATE DATABASE IF NOT EXISTS pterodactyl;"
  Q2="GRANT ALL ON pterodactyl.* TO 'panel'@'localhost' IDENTIFIED BY '$password';"
  Q3="FLUSH PRIVILEGES;"
  SQL="${Q1}${Q2}${Q3}"

  mysql -u root -e "$SQL"

  php artisan pterodactyl:env --dbhost=localhost --dbport=3306 --dbname=pterodactyl --dbuser=panel --dbpass=$password --url=http://$FQDN --timezone=$timezone --driver=memcached --queue-driver=database --session-driver=database

  php artisan migrate --force
  php artisan db:seed --force

  php artisan pterodactyl:user --firstname=$firstname --lastname=$lastname --username=$username --email=$email --password=$userpassword --admin=1

  chown -R www-data:www-data *
}

function panel_queuelisteners {
  output "Creeren van panel queue listeners"
  (crontab -l ; echo "* * * * * php /var/www/pterodactyl/html/artisan schedule:run >> /dev/null 2>&1")| crontab -

cat > /etc/systemd/system/pteroq.service <<- "EOF"
# Pterodactyl Queue Worker File
[Unit]
Description=Pterodactyl Queue Worker

[Service]
User=www-data
Group=www-data
Restart=on-failure
ExecStart=/usr/bin/php /var/www/html/pterodactyl/artisan queue:work database --queue=high,standard,low --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl enable pteroq.service
  sudo systemctl start pteroq
}

function ssl_certs {
  output "Genereren van een SSL Certificaat"
  cd /root
  curl https://get.acme.sh | sh
  cd /root/.acme.sh/
  sh acme.sh --issue --apache -d $FQDN

  mkdir -p /etc/letsencrypt/live/$FQDN
  ./acme.sh --install-cert -d $FQDN --certpath /etc/letsencrypt/live/$FQDN/cert.pem --keypath /etc/letsencrypt/live/$FQDN/privkey.pem --fullchainpath /etc/letsencrypt/live/$FQDN/fullchain.pem
}

function panel_webserver_configuration_nginx {
  output "ngingwebconf"
}

function panel_webserver_configuration_apache {
  output "Configureren van apache"
cat > /etc/apache2/sites-available/pterodactyl.conf << EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
ServerAdmin webmaster@localhost
DocumentRoot "/var/www/html/pterodactyl/public"
AllowEncodedSlashes On
php_value upload_max_filesize 100M
php_value post_max_size 100M
<Directory "/var/www/html/pterodactyl/public">
AllowOverride all
</Directory>

SSLEngine on
SSLCertificateFile /etc/letsencrypt/live/$FQDN/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/$FQDN/privkey.pem
ServerName $FQDN
</VirtualHost>
</IfModule>
EOF

echo -e "<VirtualHost *:80>\nRewriteEngine on\nRewriteCond %{SERVER_NAME} =$FQDN\nRewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,QSA,R=permanent]\n</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

  sudo ln -s /etc/apache2/sites-available/pterodactyl.conf /etc/apache2/sites-enabled/pterodactyl.conf
  sudo a2enmod rewrite
  sudo a2enmod ssl
  service apache2 restart
}

#All daemon related install functions
function update_kernel {
  output "Updating kernel als het nodig is"
  apt install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
}

function daemon_dependencies {
  output "Installeren van daemon dependecies"
  #Docker
  curl -sSL https://get.docker.com/ | sh
  systemctl enable docker

  #Nodejs
  curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
  apt install -y nodejs

  #Additional
  apt install -y tar unzip make gcc g++ python
}

function daemon_install {
  output "De daemon installeren!"
  mkdir -p /srv/daemon /srv/daemon-data
  cd /srv/daemon
  curl -Lo v0.4.3.tar.gz https://github.com/Pterodactyl/Daemon/archive/v0.4.3.tar.gz
  tar --strip-components=1 -xzvf v0.4.3.tar.gz
  npm install --only=production

  echo -e "[Unit]\nDescription=Pterodactyl Wings Daemon\nAfter=docker.service\n\n[Service]\nUser=root\n#Group=some_group\nWorkingDirectory=/srv/daemon\nLimitNOFILE=4096\nPIDFile=/var/run/wings/daemon.pid\nExecStart=/usr/bin/node /srv/daemon/src/index.js\nRestart=on-failure\nStartLimitInterval=600\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/wings.service
  systemctl daemon-reload
  systemctl enable wings
}

installchoice

case $installoption in
  1 ) webserverchoice
      required_vars_panel
      case $webserver in
        1 ) install_nginx_dependencies
            panel_downloading
            panel_installing
            panel_queuelisteners
            panel_webserver_configuration_nginx
            output "Panel installatie succesvol!"
            ;;
        2 ) install_apache_dependencies
            panel_downloading
            panel_installing
            panel_queuelisteners
            ssl_certs
            panel_webserver_configuration_apache
            output "Panel installatie succesvol!"
            ;;
      esac
      ;;
  2 ) # Daemon
      update_kernel
      daemon_dependencies
      ;;
  3 ) webserverchoice 
      required_vars_panel 
      case $webserver in 
        1 ) install_nginx_dependencies
            ;;
        2 ) install_apache_dependencies
            panel_downloading
            panel_installing
            panel_queuelisteners
            ssl_certs
            panel_webserver_configuration_apache
            output "Panel installatie succesvol!"

            update_kernel
            daemon_dependencies
            daemon_install
            output "Daemon installatie succesvol!"
            ;;
      esac
      ;;
esac

# Dankjewel voor het gebruiken van mijn script!
# Github.com/AspectDevelopment