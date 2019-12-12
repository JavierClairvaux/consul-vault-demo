#!/usr/bin/env sh
# pre reqs
nodefolder=$1;

sudo apt-get update -y
sudo apt-get install unzip -y
sudo apt-get install dnsmasq -y

cd /usr/local/bin
sudo curl -o consul.zip https://releases.hashicorp.com/consul/1.6.1/consul_1.6.1_linux_amd64.zip
sudo unzip consul.zip
sudo rm -f consul.zip
sudo mkdir -p /etc/consul.d/scripts
  # creating consul user
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir -p /opt/consul
sudo chown --recursive consul:consul /opt/consul

  # SYSTEM D
  echo '[Unit]
  Description="HashiCorp Consul - A service mesh solution"
  Documentation=https://www.consul.io/
  Requires=network-online.target
  After=network-online.target
  ConditionFileNotEmpty=/etc/consul.d/config.json
  [Service]
  User=consul
  Group=consul
  ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
  ExecReload=/usr/local/bin/consul reload
  KillMode=process
  Restart=on-failure
  LimitNOFILE=65536

  [Install]
  WantedBy=multi-user.target' | sudo tee /etc/systemd/system/consul.service

  # CONFIGURATION
  #COPING CONFIG
  sudo cp /vagrant/node_configs/$nodefolder/* /etc/consul.d


  sudo chown --recursive consul:consul /etc/consul.d
  sudo chmod 640 /etc/consul.d/config.json

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

#Install grafana
cd /home/vagrant
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install grafana -y
sudo cp /vagrant/grafana/influxdb.yml /etc/grafana/provisioning/datasources/

sudo systemctl start grafana-server
