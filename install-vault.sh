#!/bin/bash

echo "~~~~ install vault helm chart w/ ha raft and 3 pods ~~~~"
echo ""
helm install vault hashicorp/vault --set='server.image.repository=hashicorp/vault-enterprise' --set='server.image.tag=1.5.0_ent' --set='server.ha.enabled=true' --set='server.ha.raft.enabled=true'
sleep 10
echo ""
echo "~~~~ init and unseal first node ~~~~"
echo ""
echo "~~~~ wait 30 seconds for pods to come up ~~~~"
sleep 30
kubectl exec -ti vault-0 -- vault operator init -key-shares=1 -key-threshold=1 > key.txt
sleep 7
grep 'Key 1:' key.txt | awk '{print substr($NF, 1, length($NF))}' > unseal_key_space.txt
sleep 1
ansi2txt < unseal_key_space.txt > unseal_key.txt
sleep 1
grep 'Initial Root Token:' key.txt | awk '{print substr($NF, 1, length($NF))}' > root_key_space.txt
sleep 1
ansi2txt < root_key_space.txt > root_key.txt
sleep 1
kubectl exec -ti vault-0 -- vault operator unseal $(grep '' unseal_key.txt | awk '{print substr($NF, 1, length($NF))}')
sleep 7
echo ""
echo "~~~~ join and unseal second node ~~~~"
echo ""
sleep 1
kubectl exec -ti vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
sleep 7
kubectl exec -ti vault-1 -- vault operator unseal $(grep '' unseal_key.txt | awk '{print substr($NF, 1, length($NF))}')
sleep 7
echo ""
echo "~~~~ join and unseal third node ~~~~"
echo ""
sleep 1
kubectl exec -ti vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
sleep 7
kubectl exec -ti vault-2 -- vault operator unseal $(grep '' unseal_key.txt | awk '{print substr($NF, 1, length($NF))}')
sleep 7
echo ""
echo "~~~~ login to node ~~~~"
echo ""
sleep 1
kubectl exec -ti vault-0 -- vault login $(grep '' root_key.txt | awk '{print substr($NF, 1, length($NF))}')
sleep 5
echo "~~~~ raft status ~~~~"
echo ""
sleep 1
kubectl exec -ti vault-0 -- vault operator raft list-peers
sleep 5
echo "~~~~ vault-0 status ~~~~"
echo ""
sleep 1
kubectl exec -ti vault-0 -- vault status
sleep 5
echo "~~~~ vault-1 status ~~~~"
echo ""
sleep 1
kubectl exec -ti vault-1 -- vault status
sleep 5
echo "~~~~ vault-2 status ~~~~"
echo ""
sleep 1
kubectl exec -ti vault-2 -- vault status
sleep 5
echo "~~~~ init and unseal finished ~~~~"
sleep 1
echo "~~~~ license vault pods ~~~~"
echo ""
sleep 1
kubectl port-forward vault-0 8200:8200 > /dev/null 2>&1 &
sleep 3
kubectl port-forward vault-1 8201:8200 > /dev/null 2>&1 &
sleep 3
kubectl port-forward vault-2 8202:8200 > /dev/null 2>&1 &
sleep 3
export VAULT_ROOT_TOKEN=$(grep '' root_key.txt | awk '{print substr($NF, 1, length($NF))}')
sleep 1
curl --header "X-Vault-Token: $VAULT_ROOT_TOKEN" --request PUT --data @payload.json http://127.0.0.1:8200/v1/sys/license
echo ""
echo ""
curl --header "X-Vault-Token: $VAULT_ROOT_TOKEN" --request PUT --data @payload.json http://127.0.0.1:8201/v1/sys/license
echo ""
echo ""
curl --header "X-Vault-Token: $VAULT_ROOT_TOKEN" --request PUT --data @payload.json http://127.0.0.1:8200/v1/sys/license
echo ""
echo ""
echo "~~~~ license status of vault-0 ~~~~"
echo ""
curl --header "X-Vault-Token: $VAULT_ROOT_TOKEN" http://127.0.0.1:8200/v1/sys/license
echo ""
echo "~~~~ license status of vault-1 ~~~~"
echo ""
curl --header "X-Vault-Token: $VAULT_ROOT_TOKEN" http://127.0.0.1:8201/v1/sys/license
echo ""
echo "~~~~ license status of vault-2 ~~~~"
echo ""
curl --header "X-Vault-Token: $VAULT_ROOT_TOKEN" http://127.0.0.1:8202/v1/sys/license
echo ""
sleep 1
echo "cleaning up"
echo ""
rm -f unseal_key_space.txt
rm -f unseal_key.txt
rm -f root_key_space.txt
rm -f root_key.txt
killall kubectl
unset VAULT_ROOT_TOKEN
echo "~~~~ finished install ~~~~"
