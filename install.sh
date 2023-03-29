#!/bin/bash

# Stop systemd-resolved service
sudo systemctl stop systemd-resolved.service

# Edit resolved.conf file to set DNSStubListener to no
sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf

# Create a symbolic link to point /etc/resolv.conf to /run/systemd/resolve/resolv.conf
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf


#!/bin/bash

# Define the service content
SERVICE="[Unit]
Description=Clash service
After=network.target

[Service]
Type=simple
User=$(whoami)
Restart=on-failure
RestartPreventExitStatus=23
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW

ExecStart=$(pwd)/clash-linux-amd64 -d $(pwd)

[Install]
WantedBy=multi-user.target"

# Create the service file with the defined content
echo "$SERVICE" | sudo tee /etc/systemd/system/clash.service > /dev/null

# Reload the systemd daemon to read the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable clash.service

# Start the service
sudo systemctl restart clash.service


for i in {1..3}; do
    sudo ./clean_iptables_v4_v6.sh
    if [ $? -eq 0 ]; then
        break
    fi
    sleep 0.5
done

sudo ./iptables_v4_v6.sh