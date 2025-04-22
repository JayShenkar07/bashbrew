#!/bin/bash

# install-kubectl.sh
# Description: Downloads and installs the latest stable version of kubectl on Linux (amd64)

set -euo pipefail

echo "📦 Installing the latest stable version of kubectl..."

# Define variables
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
KUBECTL_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
CHECKSUM_URL="${KUBECTL_URL}.sha256"

# Download kubectl binary and checksum
echo "Downloading kubectl $KUBECTL_VERSION..."
curl -LO "$KUBECTL_URL"
curl -LO "$CHECKSUM_URL"

# Verify the checksum
echo "🔐 Verifying checksum..."
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

echo "🚀 Installing kubectl to /usr/local/bin..."
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "✅ Installation complete!"
kubectl version --client --output=yaml

# Clean up
rm -f kubectl.sha256

