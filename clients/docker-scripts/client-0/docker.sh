#client0 and client1
sudo docker run --rm -d -p 8001:8443 -p 8002:8443 \
    -p 8003:8443 -p 8004:8443 -p 8005:8443 -p 8006:8443  \
    -v $(pwd):/opt/imposter/config \
    outofcoffee/imposter-openapi:0.7.0

sudo docker run -d --network host --name payment-proxy javier1/consul-envoy -sidecar-for payment
sudo docker run -d --network host --name traffic-proxy javier1/consul-envoy -sidecar-for traffic-generator -admin-bind 127.0.0.1:19001

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
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/vault.service

sudo systemctl daemon-reload
sudo mkdir --parents /etc/vault.d
sudo cp /vagrant/vault/vault.hcl /etc/vault.d/vault.hcl
sudo chown --recursive vault:vault /etc/vault.d
sudo chmod 640 /etc/vault.d/vault.hcl
sudo systemctl start vault
