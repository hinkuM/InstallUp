# Third-Party Notices

This project automates the installation of various software packages. Below is a breakdown of the dependencies, their sources, and their respective licenses.

---

## 1. External Third-Party Repositories
The following software is fetched from specialized external repositories.

| Software | Repository URL | License |
| :--- | :--- | :--- |
| **Grafana / Loki** | [apt.grafana.com](https://apt.grafana.com) | AGPLv3 |
| **Grafana Alloy** | [apt.grafana.com](https://apt.grafana.com) | Apache 2.0 |
| **Docker / Containerd** | [download.docker.com](https://download.docker.com/linux/ubuntu) | Apache 2.0 |
| **Kubernetes** | [pkgs.k8s.io](https://pkgs.k8s.io/core:/stable:/v1.35/deb/) | Apache 2.0 |
| **Helm** | [packages.buildkite.com](https://packages.buildkite.com/helm-linux/helm-debian/any/) | Apache 2.0 |
| **Rspamd** | [rspamd.com](https://rspamd.com/apt-stable/) | Apache 2.0 |
| **Wazuh** | [packages.wazuh.com](https://packages.wazuh.com/4.x/apt/) | GPLv2 |
| **Redis Server** | [packages.redis.io](https://packages.redis.io/deb/) | AGPLv3 (v8.0+) |
| **Roundcube Webmail** | [roundcube github](https://github.com/roundcube/roundcubemail) | GPL-3.0-or-later |
| **Roundcube 2FA** | [Packagist: alexandregz/twofactor_gauthenticator](https://packagist.org/packages/alexandregz/twofactor_gauthenticator) | MIT |

### Packages installed from these repositories:
`alloy`, `wazuh-agent`, `rspamd`, `wazuh-indexer`, `wazuh-dashboard`, `wazuh-manager`, `grafana`, `loki`, `containerd.io`, `kubelet`, `kubeadm`, `kubectl`, `helm`, `roundcube`, `roundcube-plugins`,`redis-server`

---

## 2. Standard System Packages (Debian/Ubuntu)
The following packages are installed from the default operating system mirrors. They are governed by the licenses provided in their respective `/usr/share/doc/*/copyright` files (typically GPL, MIT, or BSD).

### Core Utilities & Environment
`gnupg`, `curl`, `wget`, `openssh-server`, `iptables`, `iptables-persistent`, `cron`, `lsb-release`, `ca-certificates`, `apt-transport-https`, `logrotate`, `gcc`, `libaugeas-dev`, `python3`, `python3-dev`, `python3-venv`, `python3-pip`, `python3-pymysql`, `python3-pexpect`, `debconf`, `debconf-utils`, `procps`, `adduser`, `debhelper`, `libcap2-bin`, `tar`.

### Mail Server Stack
`postfix`, `postfix-mysql`, `postfix-pcre`, `aspell`, `aspell-pl`, `nginx`, `php8.3`, `php8.3-fpm`, `php8.3-mysql`, `php8.3-mbstring`, `php8.3-intl`, `php8.3-xml`, `php8.3-curl`, `php8.3-zip`, `php8.3-gd`, `php8.3-pspell`, `php8.5`, `php8.5-fpm`, `php8.5-mysql`, `php8.5-mbstring`, `php8.5-intl`, `php8.5-xml`, `php8.5-curl`, `php8.5-zip`, `php8.5-gd`, `php8.5-pspell`, `fail2ban`, `composer`, `dovecot-core`, `dovecot-mysql`, `dovecot-imapd`, `dovecot-lmtpd`, `dovecot-sieve`, `dovecot-managesieved`.

### Logging & Monitoring
`clamav`, `clamav-daemon`, `clamav-freshclam`, `clamav-milter`, `clamdscan`, `libclamunrar`, `filebeat`, `mysql-server`, `nfs-common`, `acl`.

### Kubernetes Cluster & Cloud
`bash-completion`, `open-iscsi`, `gawk`, `util-linux`, `cryptsetup`, `dmsetup`, `skopeo`, `python3-kubernetes`, `python3-openshift`, `python3-yaml`.