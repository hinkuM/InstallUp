# Mail server automatization
This project was made to automate installation of mail server, kubernetes cluster and logging server. This is my first project this big which i spent several months on. My main goal was to learn how to automate and use these new technologies. I hope some of you will find this project useful for your own use.</br></br>
Currently installer was only tested for `ubuntu-24.04.3-live-server-amd64`, `ubuntu-26.04-live-server-amd64` (except mail server which should be run on `ubuntu-24.04.3`).
</br></br>
Installation of OS is made on minimized version of `ubuntu`.
</br>

All names of packages and some links I used are mentioned in [THIRD-PARTY-NOTICES.md](./THIRD-PARTY-NOTICES.md).

</br>

---

</br>

## 💻 Minimal tested setup
| Hostname | Role | Network | Hosts number |
| :--- | :--- | :--- | :--- |
| firewall | Manages connections from WAN to inner networks, DHCP and DNS server, controls traffic between inner networks | Between WAN and all inner networks | 1 |
| logs | Collects all logs, metrics, checks mails for viruses, backup server | LAN | 1 |
| mail | Primarily used as mail server | MAIL | 1 |
| master | Control plane for kubernetes cluster | KUBERNETES | 1 |
| slave | Agents in kubernetes cluster | KUBERNETES | 2 |
> [!IMPORTANT]
> Each network name is different network on seperate ethernet card, all created and managed by firewall

</br>

## 📄 All relevant files
```
 📦 InstallUp
 ┣━ 📂 installer
 ┃  ┣━ 📂 group_vars/                   # Variables for each group in inventory
 ┃  ┣━ 📂 host_vars/                    # Variables for specific hosts
 ┃  ┗━ 📂 roles/
 ┃     ┗━ 📂 backup/                    # IN PROGRESS (Scripts for backing up critical files)
 ┣━ 📄 inventory.yaml                   # Master list of hosts and groups
 ┣━ ⚙️ playbook_apply_ssh_K8S.yaml      # Secures K8s SSH (certs)
 ┣━ ⚙️ playbook_apply_ssh_lan.yaml      # Secures LAN SSH (certs)
 ┣━ ⚙️ playbook_deploy_certs.yaml       # Runs all roles using certficates to restart them after deploying cert files
 ┣━ ⚙️ playbook_kubernetes.yaml         # K8s cluster setup (master, worker)
 ┣━ ⚙️ playbook_lan.yaml                # LAN infra setup (mail, log servers)
 ┣━ ⚙️ playbook_renew_certs.yaml        # Deletes all certificates and creates new ones on LOGS host
 ┗━ 🔑 playbook_ssh_key_change.yaml     # Replaces or removes SSH keys
```

</br>

## 🔥 Step by step on how this *beast* work
  0. Install: ansible-core, python3, ssh-askpass; SSH into all hosts to save fingerprint
  1. Configurate one host (usually **firewall**) to handle **DNS**, **DHCP**, **NAT forwarding** (for *mail server*), **firewall rules** for each local network
      - I'm using [OPNsense](https://opnsense.org/) as `firewall`
      - Each local network (`MAIL`, `LAN`, `KUBERNETES`) is different ethernet card
  2. Connect all computers to networks they should belong to
      - Every network is just switch with all hosts connected to it
          - **Mail network** - Only mail server/s
          - **LAN network** - VPN clients, *logs server* and other hosts used by other networks (*KMS* for example)
          - **KUBERNETES network** - Kubernetes control plane and agents,</br> (*easier to manage firewall rules on OPNsense rather than fight with kubernetes*)
  3. Create and insert plain text password into `.vault_pass` file (set permissions to 600) for ansible vault encryption, same directory as `START.sh`
  4. Read and adjust variables in `inventory.yaml` and inside folders `group_vars/` and `host_vars/`
      - Each folder's name is related to group (`group_vars/`) or custom name inside every `hosts` list for each computer (`host_vars/`) mentioned in `inventory.yaml`
      - `vault.yaml` files should be encrypted after changing values, either by command [here](#️-useful-commands-during-configuration) or `START.sh`
  5. Before running script or using commands remember to <ins>SSH into each hosts</ins> using SSH keys inside `installer/ssh_keys/` to save fingerprints
  6. Run `START.sh` or [these](#️-manual-start-commands) commands in order

> [!NOTE]
> i'm planning to add configuration template for OPNsense which you could just import and use

</br>
  
## ✏️ Manual start commands

Remember to change `./` directory so it will point to file correctly. </br>
Working dir should be same as location of `README.md` file.

### 🐑 LAN

- First time running script for `LAN`, **before main playbook** (*ssh with password*)
```
ansible-playbook -i "./installer/inventory.yaml" "./installer/playbook_apply_ssh_lan.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --vault-password-file "./.vault_pass" -e "ansible_port=22"
```
- Main playbook (*ssh with certificates*)
```
ansible-playbook -i "./installer/inventory.yaml" "./installer/playbook_lan.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --tags "" --vault-password-file "./.vault_pass"
```

### 🐱 KUBERNETES

- First time running script for `KUBERNETES`, **before main playbook** (*ssh with password*)
```
ansible-playbook -i "./installer/inventory.yaml" "./installer/playbook_apply_ssh_k8s.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --vault-password-file "./.vault_pass" -e "ansible_port=22"
```

- Main playbook (*ssh with certificates*)
```
ansible-playbook -i "./installer/inventory.yaml" "./installer/playbook_kubernetes.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --tags "" --vault-password-file "./.vault_pass"
```

### 🦣 ALL

- Playbook used to remove/replace SSH keys
```
ansible-playbook -i "./installer/inventory.yaml" "./installer/playbook_ssh_key_change.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --tags "" --vault-password-file "./.vault_pass"
```

</br>

## 📦 Created folders/files inside `./installer/`
| File/Folder | Content |
| :--- | :--- |
| `certificates/` | All client certificates |
| `ssh_keys/` | SSH keys to all hosts |
| `DKIM_values/` | DKIM values needed to create DNS records |
| `join_command.sh` | Bash command that allow agents to join kubernetes cluster |

</br>

## 💸 End results
  - Configurated **mail server** to send and receive mails
      - One domain is binded to public IP, rest is not
  - Logging server with **wazuh and grafana dashboards** ~~(some basic dashboard included in grafana)~~
      - Every host is connected to wazuh server and all important **logs are sent to loki** for grafana to display
  - Ready to work **kubernetes cluster** with one control plane and multiple agents

</br>

## ❓ Additional information
Currently isntallation won't work for more than 1 host in these groups: `MAIL`, `LOGS`, `MASTER` because of how some variables and loops are set in ansible. </br>
I strongly advise you to read every comment for each variable I made and to not instantly expose it to network. </br></br>
Reason? This is my first project with purpose to really use it and not to let it rot on my disk. I'm currently testing it for any flaws and potential exploits so be aware of that. If you really want to use it you should test it first and maybe report anything if you find any bugs 😌. </br></br>
As for `firewall` configuration, there is a lot of things that needs to be set there to work properly with my project so I will, in near future, add configuration file as I mentioned earlier.

</br>

---------------------------------------------------------------------------------

## ⛓️ Useful commands during configuration

To speed up logging into hosts using SSH add code below to `~/.ssh/config` file then you can just simply use `ssh example_hostname`
```
Host example_hostname
    HostName 192.168.1.10 # or FQDN
    User remote_user
    IdentityFile ~/.ssh/user_rsa
    Port 22
```

</br>

Command for SHA512 password to put into MySQL database for mail users
```
openssl passwd -6 your_password_here
```

</br>

Changes all password on wazuh server
```
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/wazuh-passwords-tool.sh --change-all
```

</br>

Encrypts and decrypts ansible vault files (can be done with `START.sh` script)
```
# DECRYPT
ansible-vault decrypt /path/to/vault.yaml --vault-password-file .vault_pass

# ENCRYPT
ansible-vault encrypt /path/to/vault.yaml --vault-password-file .vault_pass
```

</br>

When prometheus is giving errors 'Out of bounds' check for time on your pc, sometimes there is need to
```
apt purge chrony
```