#!/usr/bin/env sh

clientfolder=$1;

sudo apt-get update -y
sudo apt-get install unzip -y
sudo apt-get install dnsmasq -y
# sudo apt-get install \
#     apt-transport-https \
#     ca-certificates \
#     curl \
#     gnupg-agent \
#     software-properties-common -y
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# sudo apt-key fingerprint 0EBFCD88
# sudo add-apt-repository \
#    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
#    $(lsb_release -cs) \
#    stable"
# sudo apt-get install docker-ce docker-ce-cli containerd.io -y
# sudo groupadd docker
# sudo usermod -aG docker $USER
# newgrp docker
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

#Install vault
echo "installing vault"

cd /usr/local/bin
sudo wget -q https://releases.hashicorp.com/vault/1.2.4/vault_1.2.4_linux_amd64.zip
sudo unzip vault_1.2.4_linux_amd64.zip
sudo rm vault_1.2.4_linux_amd64.zip
chmod +x vault
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
export VAULT_ADDR=http://127.0.0.1:8200
