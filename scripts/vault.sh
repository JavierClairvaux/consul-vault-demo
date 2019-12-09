#Run on a vault instance after unsealing
export VAULT_ADDR=http://127.0.0.1:8200


#Login as root
vault login <ROOT_TOKEN>
#Enable secrets at database
vault secrets enable database

#Generate policy and token
vault policy write postgres /vagrant/vault_policies/postgres.hcl
vault token create --policy=postgres

#Config vault-postgres connection on vault
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="app" \
    connection_url="postgresql://vault:secret@postgres.service.consul:5432/myapp?sslmode=disable"

#Config postgres credentials
vault write database/roles/app \
    db_name=postgresql \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
    default_ttl="10s" \
    max_ttl="24h"

#To get credentials
curl  --header "X-Vault-Token: ..."  http://vault.service.consul:8200/v1/database/creds/app | jq
