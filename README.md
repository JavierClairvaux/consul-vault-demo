# consul-vault-demo
Instructions:

1. Run vagrant up on main dir

2. Run vagrant up vault-client-3 on clients dir

3. Run vagrant up on the rest of the clients

4. Run vault operator init on each vault node

5. Unseal all the vaults

6. Follow steps on vault.sh

7. run export POSTGRES_TOKEN=< postgres token obtained on previous step >

8. run watch -n 5 bash traffic-generator.sh on vault-client-4

9. Export Grafana dashboard and see mtrics on localhost:3000
