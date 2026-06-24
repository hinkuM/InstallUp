#!/bin/bash
CURRENT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
KEYS_DIR="${CURRENT_DIR}/installer/ssh_keys"
#h
mkdir -p ${KEYS_DIR}
chmod 0700 ${KEYS_DIR}
clear

printf "/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\ \n\n"

printf "Create/delete existing ssh keys: 1\n"
printf "Installation of mail server: 2\n"
printf "Installation of kubernetes cluster: 3\n"
printf "Encrypt or decrypt ansible vault files: 4\n"
printf "Recreate certificates for all machines: 5\n"
printf "Create certificate for new client host: 6\n"
printf "Exit: 9\n\n"

printf "/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\ \n\n"

read -p "You choose: " ACTION

clear

ssh_keys() {
    SSH_KEY_NAME="init"
    PASSPHRASE=""

    while [ -n "$SSH_KEY_NAME" ]; do
        read -p "Name of next ssh keys (Leave blank to stop): " SSH_KEY_NAME
        if [ "$SSH_KEY_NAME" == "" ]; then
        clear
            continue
        fi

        REPLACE="y"

        if [ -e "${KEYS_DIR}/${SSH_KEY_NAME}" ]; then 
            REPLACE=""
        fi

        while [[ "$REPLACE" != "y" && "$REPLACE" != "n" ]]; do 
            REPLACE=""
            read -p "Do you want to overwrite this certificate? y/n: " REPLACE
        done
        
        if [ "$REPLACE" == "n" ]; then
            clear
            echo "Key was not replaced"
            continue
        fi

        if [[ -n "$SSH_KEY_NAME" && "$REPLACE" != "n" ]]; then
            read -p "Enter passphrase for key (Leave blank to disable): " PASSPHRASE
            KEY_PATH="${KEYS_DIR}/${SSH_KEY_NAME}"
            ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "$PASSPHRASE" -q
            clear
            printf "Created key: ${SSH_KEY_NAME}\n"
            printf "Passphrase: ${PASSPHRASE}\n\n"
        fi
    done
    return 0
}

installation() {
    TAGS=""
    SKIP_TAGS=""
    FIRST="y"
    read -p "First time running script? (y - yes, n - no): " FIRST
    clear
    printf "(leave empty or enter them like this: tag1,tag2,tag3)\n"
    read -p "Select tags to RUN all tasks with it (empty - all tags): " TAGS
    read -p "Select tags to SKIP all tasks with it (empty - skip none): " SKIP_TAGS
    if [[ ($FIRST == "yes" || $FIRST == "y") && $ACTION == "2" ]]; then
        ansible-playbook -i "${CURRENT_DIR}/installer/inventory.yaml" "${CURRENT_DIR}/installer/playbook_apply_ssh_lan.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --vault-password-file "${CURRENT_DIR}/.vault_pass" -e "ansible_port=22"
    fi
    if [[ ($FIRST == "yes" || $FIRST == "y") && $ACTION == "3" ]]; then
        ansible-playbook -i "${CURRENT_DIR}/installer/inventory.yaml" "${CURRENT_DIR}/installer/playbook_apply_ssh_k8s.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --vault-password-file "${CURRENT_DIR}/.vault_pass" -e "ansible_port=22"
    fi
    if [[ -n "$TAGS" || -n "$SKIP_TAGS" ]]; then
        if [ $ACTION == "2" ]; then
            ansible-playbook -i "${CURRENT_DIR}/installer/inventory.yaml" "${CURRENT_DIR}/installer/playbook_lan.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --tags "${TAGS}" --skip-tags "${SKIP_TAGS}" --vault-password-file "${CURRENT_DIR}/.vault_pass"
        else
            ansible-playbook -i "${CURRENT_DIR}/installer/inventory.yaml" "${CURRENT_DIR}/installer/playbook_kubernetes.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --tags "${TAGS}" --skip-tags "${SKIP_TAGS}" --vault-password-file "${CURRENT_DIR}/.vault_pass"
        fi
    else
        if [ $ACTION == "2" ]; then
            ansible-playbook -i "${CURRENT_DIR}/installer/inventory.yaml" "${CURRENT_DIR}/installer/playbook_lan.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --vault-password-file "${CURRENT_DIR}/.vault_pass"
        else
            ansible-playbook -i "${CURRENT_DIR}/installer/inventory.yaml" "${CURRENT_DIR}/installer/playbook_kubernetes.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --vault-password-file "${CURRENT_DIR}/.vault_pass"
        fi
    fi
    return 0
}

ansible_vault() {
    ENCRYPT=""
    ALL=""
    COMMAND="encrypt"
    read -p "Encrypt or decrypt? (1 - encrypt, 2 - decrypt) " ENCRYPT
    read -p "Do it for all files or just one? (1 - all, [folder_name] - specific file) " ALL

    if [ "$ENCRYPT" == "2" ]; then
        COMMAND="decrypt"
    elif [ "$ENCRYPT" != "1" ]; then
        printf "Wrong option!\n"
        ansible_vault
        return 0
    fi

    if [ "$ALL" == "1" ]; then
        readarray -d '' MY_FILES < <(find "${CURRENT_DIR}/installer/" -type f -name "vault.y*ml" -print0)
    elif [ -n "$ALL" ]; then
        readarray -d '' MY_FILES < <(find "${CURRENT_DIR}/installer/" -type f -path "*/${ALL}/vault.y*ml" -print0)
    else
        clear
        printf "Wrong file!\n"
        ansible_vault
        return 0
    fi

    for file in "${MY_FILES[@]}"; do
        ansible-vault "${COMMAND}" "${file}" --vault-password-file "${CURRENT_DIR}/.vault_pass"
    done

    return 0
}

certificates() {
    TAGS=""
    printf "(WARNING: 'server' or 'clients' alone assumes Root CA already exists)\n"
    printf "(leave empty or enter them like this: tag1,tag2,tag3)\n"
    printf "(you can choose to recreate certificates: ca (all), server (server only), clients (client only))\n"
    printf "(by default - ca - is selected)\n\n"
    read -p "Select ca, server or clients: " TAGS
    if [[ -n "$TAGS" ]]; then
        ansible-playbook -i "${CURRENT_DIR}/installer/inventory.yaml" "${CURRENT_DIR}/installer/playbook_renew_certs.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --tags "${TAGS}" --vault-password-file "${CURRENT_DIR}/.vault_pass"
    else
        ansible-playbook -i "${CURRENT_DIR}/installer/inventory.yaml" "${CURRENT_DIR}/installer/playbook_renew_certs.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --tags "ca" --vault-password-file "${CURRENT_DIR}/.vault_pass"
    fi
    ansible-playbook -i "${CURRENT_DIR}/installer/inventory.yaml" "${CURRENT_DIR}/installer/playbook_deploy_certs.yaml" -e 'ansible_python_interpreter=/usr/bin/python3' --tags "certificates,file,once,handler,pod" --vault-password-file "${CURRENT_DIR}/.vault_pass"  -e "force_wazuh_security_init=true"
    return 0
}

new_client_cert() {
    NEW_HOST=""
    read -p "Insert hostname of new client: " NEW_HOST
    if [[ -z "$NEW_HOST" ]]; then
        echo "Error: hostname cannot be empty"
        return 1
    fi    
    ansible-playbook -i "${CURRENT_DIR}/installer/inventory.yaml" "${CURRENT_DIR}/installer/playbook_create_client_cert.yaml" -e "ansible_python_interpreter=/usr/bin/python3 hostname=${NEW_HOST}" --vault-password-file "${CURRENT_DIR}/.vault_pass"
}

case $ACTION in
  "1") ssh_keys ;;
  "2") installation ;;
  "3") installation ;;
  "4") ansible_vault ;;
  "5") certificates ;;
  "6") new_client_cert ;;
  "9") exit ;;
  *) exit ;;
esac