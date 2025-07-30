#!/bin/bash

# Log output to help with debugging
exec > /var/log/startup-script.log 2>&1
set -x

# Function to wait for apt lock
wait_for_apt_lock() {
    echo "Waiting for apt lock..."
    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
        echo "Lock still held, waiting..."
        sleep 5
    done
}

# Wait before apt operations
wait_for_apt_lock

# Update and install dependencies
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Wait again just in case
wait_for_apt_lock

# Install Docker
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Verify Docker installation
docker --version
