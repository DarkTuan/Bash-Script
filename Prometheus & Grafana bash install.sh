#!/bin/bash
# cai dat thoi gian va update ubuntu

apt update
timedatectl set-timezone "Asia/Ho_Chi_Minh"
timedatectl set-ntp true
systemctl restart systemd-timesyncd


export RELEASE="2.20.1"
wget https://github.com/prometheus/prometheus/releases/download/v${RELEASE}/prometheus-${RELEASE}.linux-amd64.tar.gz
tar xvf prometheus-${RELEASE}.linux-amd64.tar.gz
cd prometheus-${RELEASE}.linux-amd64/

groupadd --system prometheus
grep prometheus /etc/group
useradd -s /sbin/nologin -r -g prometheus prometheus
mkdir -p /etc/prometheus/{rules,rules.d,files_sd}  /var/lib/prometheus
cp prometheus promtool /usr/local/bin/
cp -r consoles/ console_libraries/ /etc/prometheus/
cp prometheus.yml /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus/  /var/lib/prometheus/
chmod -R 775 /etc/prometheus/ /var/lib/prometheus/

touch /etc/systemd/system/prometheus.service

echo " [Unit]
Description=Prometheus systemd service unit
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/prometheus \
--config.file=/etc/prometheus/prometheus.yml \
--storage.tsdb.path=/var/lib/prometheus \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries \
--web.listen-address=0.0.0.0:9090 \
--storage.tsdb.retention.time=1y
SyslogIdentifier=prometheus
Restart=always
[Install]
WantedBy=multi-user.target " > /etc/systemd/system/prometheus.service

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

####################################################################################
#GRAFANA SETUP

echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add

apt-get update
apt-get install grafana -y
systemctl start grafana-server
systemctl enable grafana-server.service

####################################################################################
#NGINX SETUP VHOST


sudo apt install nginx

rm /etc/nginx/sites-enabled/default

cd /etc/nginx
sudo apt install apache2-utils
htpasswd -c /etc/nginx/.htpasswd admin
cd /etc/nginx/sites-enabled/
ls -l
nginx -t
sudo service nginx restart
sudo service nginx status

cd /etc/nginx/sites-enabled
echo "
server {
    server_name  cuuvanlongsutien.xyz;
    listen 81;
    listen [::]:81;
    auth_basic "Private Property";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass           http://localhost:9090/;
    }
}" > prometheus

echo "
server {
    server_name  cuuvanlongsutien.xyz;
    listen 80;
    listen [::]:80;

    location / {
        proxy_pass           http://localhost:3000/;
    }
}" > grafana

nginx -t
sudo service nginx restart
sudo service nginx status