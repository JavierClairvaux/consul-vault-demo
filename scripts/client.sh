#!/bin/bash

clientfolder=$1;

IFS='-'
read -ra ADDR <<< "$clientfolder"
i="${ADDR[1]}"
IFS=' '
sudo apt-get update -y
sudo apt-get install jq unzip -y
sudo apt-get install dnsmasq -y

# Install consul
sudo wget -q https://cab-consul.s3.us-east-2.amazonaws.com/consul
chmod +x consul
sudo mv consul /usr/local/bin
sudo mkdir -p /etc/consul.d/scripts

# creating consul user
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir -p /opt/consul
sudo chown --recursive consul:consul /opt/consul

# SYSTEM D
echo '[Unit]
Description="HashiCorp Consul Agent"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/config.json

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/ -enable-local-script-checks
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=on-failure
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/consul.service

# CONFIGURATION
# COPING CONFIGURATION
sudo cp /vagrant/client_configs/$clientfolder/* /etc/consul.d/


# Adding basic services echo web
nohup python3 -m http.server 7001 &



# finally starting consul
sudo systemctl daemon-reload
sudo systemctl start consul
sudo systemctl status consul

# dns masq update
# Netmask
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved

sudo rm /etc/resolv.conf
echo "
  nameserver 127.0.0.1
  nameserver 8.8.8.8
" | sudo tee /etc/resolv.conf;

# creating consul dnsmasq
# disabling
echo "
# Forwarding lookup of consul domain
server=/consul/127.0.0.1#8600
" | sudo tee /etc/dnsmasq.d/10-consul

sudo systemctl restart dnsmasq
if [ $i -lt 2 ]
then
  #Install vault
  echo "INSTALLING VAULT"

  cd /usr/local/bin
  sudo wget -q https://releases.hashicorp.com/vault/1.3.0/vault_1.3.0_linux_amd64.zip
  sudo unzip vault_1.3.0_linux_amd64.zip
  sudo rm vault_1.3.0_linux_amd64.zip
  sudo chmod +x vault
  vault -autocomplete-install
  complete -C /usr/local/bin/vault vault
  sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
  sudo useradd --system --home /etc/vault.d --shell /bin/false vault
  echo '[Unit]
  Description=Vault secret management tool
  Requires=network-online.target
  After=network-online.target

  [Service]
  User=vault
  Group=vault
  PIDFile=/var/run/vault/vault.pid
  ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl -log-level=debug
  ExecReload=/bin/kill -HUP $MAINPID
  KillMode=process
  KillSignal=SIGTERM
  Restart=on-failure
  RestartSec=42s
  LimitMEMLOCK=infinity

  [Install]
  WantedBy=multi-user.target' | sudo tee /etc/systemd/system/vault.service

  sudo systemctl daemon-reload
  sudo mkdir --parents /etc/vault.d
  sudo cp /vagrant/vault/$clientfolder/vault.hcl /etc/vault.d/vault.hcl
  sudo chown --recursive vault:vault /etc/vault.d
  sudo chmod 640 /etc/vault.d/vault.hcl
  sudo systemctl start vault

  #Install telegraf
  curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
  source /etc/lsb-release
  echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
  sudo apt-get update && sudo apt-get install telegraf
  sudo rm  /etc/telegraf/telegraf.conf
  sudo cp /vagrant/telegraf/telegraf.conf  /etc/telegraf/

  sudo systemctl start telegraf
  sleep 5
  sudo systemctl restart telegraf

elif [ $i -eq 2 ]
then
  echo "INSTALLING POSTGRES"
  #install docker
  sudo apt-get install \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg-agent \
      software-properties-common -y
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo apt-key fingerprint 0EBFCD88
  sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
  sudo apt-get install docker-ce docker-ce-cli containerd.io -y

  sudo docker run -d --network host -e POSTGRES_DB=myapp -e POSTGRES_USER=vault -e POSTGRES_PASSWORD=secret --name postgres postgres
  sudo docker run -d --network host --name postgres-proxy javier1/consul-envoy -sidecar-for postgres
  sudo docker exec postgres psql -U vault -c "CREATE ROLE app;" myapp

elif [ $i -eq 3 ]
then
  echo "installing influxdb"
  ##Install docker
  sudo apt-get install \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg-agent \
      software-properties-common -y
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo apt-key fingerprint 0EBFCD88
  sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
  sudo apt-get install docker-ce docker-ce-cli containerd.io -y

  #Install influxdb
  sudo curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
  source /etc/lsb-release
  echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
  sudo apt-get update
  sudo apt-get install influxdb -y
  sudo systemctl start influxd
  sudo apt install influxdb-client
  influx -execute "create database telegraf create user telegraf with password 'pass'"

  sudo docker run -d --network host --name influxdb-proxy javier1/consul-envoy -sidecar-for influxdb

elif [ $i -eq 4 ]
then
  cd /home/vagrant
  sudo cp /vagrant/traffic-gen/traffic-generator.sh .
  sudo apt-get install postgresql-client -y
fi
