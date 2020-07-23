# vault-k8s-sandbox
bash script to install vault helm chart in k8s.

- Tested for non-production use on Ubuntu 18.04.
- Assumes kubectl and gcloud environment setup to proper GCP cluster.
- Assumes ansi2txt package is installed - sudo apt install colorized-logs.
- Assumes vault license payload.json is in current working directory.
- Assumes vault pod names to be vault-0, vault-1, and vault-2 - can be changed to variables later on.
- Assumes no other kubectl port-forwards are in use and localhost has access to ports 8200, 8201, and 8202.

What It Does
* Installs vault helm chart with raft-ha values sets.
* Init and unseal vault-0 pod.
* Raft join and unseal vault-1 pod.
* Raft join and unseal vault-2 pod.
* License vault-0, vault-1, and vault-2 pods.

Usage
* chmod +x install-vault.sh
* ./install-vault.sh
* script takes about 2-5 minutes to complete.
* cleanup keeps key.txt file with root key and unseal key in working directory.
