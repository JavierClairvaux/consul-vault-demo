#Install influxdb
sudo curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
sudo apt-get update
sudo apt-get install influxdb -y
sudo systemctl start influxd
sudo apt install influxdb-client
influx -execute "create database telegraf
create user telegraf with password 'pass'"

sudo docker run -d --network host --name influxdb-proxy javier1/consul-envoy -sidecar-for influxdb
