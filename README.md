# Mail server automatization
This project was made to automate installation of mail server, kubernetes cluster and logging server. This is my first project this big which i spent several months on. My main goal was to learn how to automate and use these new technologies. I hope some of you will find this project useful for your own use.


All names of packages and some links I used are mentioned in **THIRD-PARTY-NOTICES.md**.

## Minimal tested setup
| Hostname | Role | Network | Hosts number |
| :--- | :--- | :--- | :--- |
| firewall | Manages connections from WAN to inner networks, DHCP and DNS server, controls traffic between inner networks | Between WAN and all inner networks | 1 |
| logs | Collects all logs, metrics, checks mails for viruses, backup server | LAN | 1 |
| mail | Primarily used as mail server | MAIL | 1 |
| master | Control plane for kubernetes cluster | KUBERNETES | 1 |
| slave | Agents in kubernetes cluster | KUBERNETES | 2 |
> Each network name is different network on seperate ethernet card, all created and managed by firewall

---------------------------------------------------------------------------------

### All relevant files are stored in:
 - `group_vars` - variables for each group inside `inventory.yaml`
 - `host_vars` - variables for each host inside `inventory.yaml`
 - `inventory.yaml` - list of hosts and groups
 - `playbook_apply_ssh_lan` - changes ssh from password to certificates and saves fingerprints (**LAN**)
 - `playbook_apply_ssh_K8S` - changes ssh from password to certificates and saves fingerprints (**KUBERNTES**)
 - `playbook_lan` - installation for cluster (**master**, **slave**)
 - `playbook_kubernetes` - installation for LAN (**mail**, **logs servers**)
 - `playbook_ssh_key_change` - for replacing/removing SSH keys
 - ~~`roles/backup/*` - scripts responsible for making copy of important files~~ *in progress*


### To run this installator you will need:
  - `.vault_pass` - Plain text of your password in a file, used to encrypt ansible vault files with credentials, same directory as `START.sh`
  - All variables set in `group_vars`, `host_vars`, `inventory.yaml` - There are comments to each variable in every file and templates of vault files
  - Working **firewall** that handles **DNS**, **DHCP**, **NAT forwarding** (for mail server), **firewall rules** for each subnetwork
  - Currently installer was only tested for `ubuntu-24.04.3-live-server-amd64`, `ubuntu-26.04-live-server-amd64` (except mail server which should be run on *ubuntu-24.04.3*)
  - Installation of OS is made on minimized version of `ubuntu`
  - Installer is based on topology with 3 subnetworks (every network is just switch with all computers connected to it):
    - **Mail network** - Only mail server
    - **LAN network** - VPN clients, logs server and other servers/computers used by other networks
    - **Kubernetes network** - It is easier to manage firewall rules on OPNsense rather than fight with kubernetes
> i'm planning to add configuration template for OPNsense which you could just import and use
  
### If you ensure everything from the list above is done you can:
  - Run bash script `START.sh`
  - Use commands listed below to run installation manually (working dir should be same as location of this file)

```
# REMEMBER TO CHANGE ./ DIRECTORY SO IT WILL POINT TO FILE CORRECTLY

#FIRST TIME USE BEFORE playbook_lan.yaml (USES SSH WITH PASSWORD NOT CERTIFICATES) LAN
ansible-playbook -i "./installer/inventory.yaml" "./installer/playbook_apply_ssh_lan.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --vault-password-file "./.vault_pass" -e "ansible_port=22"

#FIRST TIME USE BEFORE playbook_kubernetes.yaml (USES SSH WITH PASSWORD NOT CERTIFICATES) KUBERNETES
ansible-playbook -i "./installer/inventory.yaml" "./installer/playbook_apply_ssh_k8s.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --vault-password-file "./.vault_pass" -e "ansible_port=22"

#LAN INSTALLER (MAIL + LOGS)
ansible-playbook -i "./installer/inventory.yaml" "./installer/playbook_lan.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --tags "" --vault-password-file "./.vault_pass"

#KUBERNETES INSTALLER (MASTER + AGENT)
ansible-playbook -i "./installer/inventory.yaml" "./installer/playbook_kubernetes.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --tags "" --vault-password-file "./.vault_pass"

#REMOVE/REPLACE SSH KEYS
ansible-playbook -i "./installer/inventory.yaml" "./installer/playbook_ssh_key_change.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --tags "" --vault-password-file "./.vault_pass"

```

## Installer will create these folders/file in `installer/` directory:
  - `certificates/` - Contains all client certificates
  - `ssh_keys/` - SSH keys to all hosts
  - `DKIM_values/` - All DKIM values needed to create DNS records
  - `join_command.sh` - Bash command that allow agents to join kubernetes cluster

## **End results** are:
  - Fully configurated **mail server** (one domain is binded to public IP, second domain is not)
  - Logging server with **wazuh and grafana dashboards** ~~(some basic dashboard included in grafana)~~
  - Every configurated host is connected to wazuh server and all important **logs are sent to loki**
  - Ready to work **kubernetes cluster** with one control plane and multiple agents

---------------------------------------------------------------------------------

## You can find useful commands below.

To speed up logging into hosts using SSH add code below to `~/.ssh/config` file then you can just simply use `ssh example_hostname`
```
Host example_hostname
    HostName 192.168.1.10 # or FQDN
    User remote_user
    IdentityFile ~/.ssh/user_rsa
    Port 22
```

Command for SHA512 password to put into MySQL database for mail users
```
openssl passwd -6 your_password_here
```

Changes all password on wazuh server
```
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/wazuh-passwords-tool.sh --change-all
```

Encrypts and decrypts ansible vault files (can be done with `START.sh` script)
```
# DECRYPT
ansible-vault decrypt /path/to/vault.yaml --vault-password-file .vault_pass

# ENCRYPT
ansible-vault encrypt /path/to/vault.yaml --vault-password-file .vault_pass
```

When prometheus is giving errors 'Out of bounds' check for time on your pc, sometimes there is need to
```
apt purge chrony
```