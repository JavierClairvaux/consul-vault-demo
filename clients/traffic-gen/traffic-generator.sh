data=`curl  --header "X-Vault-Token: $POSTGRES_TOKEN"  http://vault.service.consul:8200/v1/database/creds/app`
export PGUSER=`echo $data | jq -r '.data.username'`
export PGPASSWORD=`echo $data | jq -r '.data.password'`
psql -h postgres.service.consul  -c "SELECT current_user;" myapp
