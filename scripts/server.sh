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
echo $dcfolder

consul config write /vagrant/central_config/consul/payment-defaults.hcl

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


# #Install influxdb
# sudo curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
# source /etc/lsb-release
# echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
# sudo apt-get update
# sudo apt-get install influxdb -y
# sudo systemctl start influxd
# sudo apt install influxdb-client
# influx -execute "create database telegraf
# create user telegraf with password 'pass'"

#Install telegraf
cat <<EOF | sudo tee /etc/apt/sources.list.d/influxdata.list
deb https://repos.influxdata.com/ubuntu bionic stable
EOF
sudo curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install telegraf
cd /home/vagrant
cd /etc/telegraf/
sudo cp /vagrant/telegraf/telegraf.conf .
sudo mv telegraf.conf telegraf.conf.default
sudo cp /vagrant/telegraf/telegraf.conf .
sudo systemctl start telegraf

#Install prometheus
cd /home/vagrant
mkdir tmp
cd tmp/
cp /vagrant/prometheus/$nodefolder/prometheus.yml .
sudo docker run -d --network host -v $(pwd):/etc/prometheus/ --name prometheus prom/prometheus
sudo systemctl restart telegraf

#Install grafana
cd /home/vagrant
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install grafana -y
sudo cp /vagrant/grafana/influxdb.yml /etc/grafana/provisioning/datasources/

sudo systemctl start grafana-server
