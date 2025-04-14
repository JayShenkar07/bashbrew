#!/bin/bash

# Function to wait for the apt lock to be released
wait_for_apt_lock() {
    echo "Waiting for apt lock..."
    while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 || sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
        echo "Lock still held, waiting..."
        sleep 5
    done
}

# Wait for any apt processes to finish
wait_for_apt_lock

sudo apt-get update -y

sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Wait for any apt processes to finish again before installing Docker
wait_for_apt_lock

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl start docker
sudo systemctl enable docker

sudo docker --version

sudo usermod -aG docker $USER

newgrp docker

echo "Docker has been installed and configured. Please log out and log back in if you encounter any permission issues."
