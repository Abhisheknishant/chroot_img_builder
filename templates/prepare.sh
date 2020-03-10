#!/usr/bin bash

# Resize File system
parted /dev/sda resizepart 2 4500
resize2fs /dev/sda2

# Add a public ssh key
mkdir -p /root/.ssh
cat << EOF1 >> /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCym4/7FJSQvRwy6yV+oGhyNk1ImaQ8byjTG7U9wKD2pFBQlF7sxa0v7QZNI+RKqUuZkeTNL79HBd44FqoMcssczoZoVxp72B3vas7lGmvZulO8dZlxqBtD/kc9HX+1eEnMw9s+NfbNMH+l/4LZQRvx8NLVqlms86DRoOwFFWNVQRRkihHAKxv6wvmqiPKuE/3omHdht6PpXS7n9S3UMjIV/KBzAHOUpQz/lYYa/SgAId48CAo8hnuEewOsNwIP/U9X/zUMrQyLoop1VctsM8oEhHOjZbrE3dFGfS8rMoaVyC+zhVetCnbFNS8PQo0qHWXM7OnA8ceoGyEkh5A+Hhfr jonathan@artoo.local
EOF1

# Proceed with the installation
apt update
apt install -y tmux nodejs git

exit 0