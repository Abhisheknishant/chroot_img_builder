#!/usr/bin bash

df -lh

if [ ! -d /var/lib/c9sdk ]; then
   git clone https://github.com/c9/core.git /var/lib/c9sdk
fi

df -lh

cd /var/lib/c9sdk
sed -i "s/\$DOWNLOAD \$URL\/master\/install.sh | bash/\$DOWNLOAD \$URL\/master\/install.sh | sed 's\/<= 2.2\/<= 2.8\/g' | bash/g" scripts/install-sdk.sh
bash scripts/install-sdk.sh

df -lh

#nodejs /var/lib/c9sdk/server.js -l 0.0.0.0 -a name:passwd -w /root

mkdir /workspace

cat << EOF1 > /etc/systemd/system/c9.service
[Unit]
Description=Cloud9 IDE
Requires=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/c9
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF1

cat << EOF2 > /usr/local/bin/c9
#!/bin/sh
USERNAME="pi"
PASSWORD="raspberry"

nodejs /var/lib/c9sdk/server.js -l 0.0.0.0 \
    --listen 0.0.0.0 \
    --port 8181 \
    -a \$USERNAME:\$PASSWORD \
    -w /workspace
EOF2

chmod +x /usr/local/bin/c9

systemctl daemon-reload
systemctl start c9
systemctl enable c9

df -lh

# Install packages for enabling python debugger in Cloud9
apt install -y python-dev python-pip
pip install ikpdb

# Enable SSH
touch /boot/ssh

df -lh

exit 0
