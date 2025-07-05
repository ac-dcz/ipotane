#!/bin/bash

# This script installs Docker on Debian-based (Ubuntu) or RHEL-based (CentOS) systems
# following the official documentation.
# It requires sudo privileges to execute.

set -e # Exit immediately if a command exits with a non-zero status.

# Helper for logging
log() {
    echo ">>> ${*}"
}

# --- Check if Docker is already installed ---
if command -v docker &>/dev/null; then
    log "Docker is already installed. Version details:"
    docker --version
    exit 0
fi

# --- OS Detection ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    log "Cannot detect operating system from /etc/os-release. Aborting."
    exit 1
fi

log "Detected OS: $OS"

# --- Install based on detected OS ---
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    # --- Uninstall old versions on Debian/Ubuntu ---
    log "Checking for and removing any old Docker versions..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        if dpkg -l | grep -q " $pkg "; then
            sudo apt-get remove -y $pkg
        fi
    done

    # --- Set up Docker's apt repository ---
    log "Setting up Docker's apt repository..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # --- Install Docker packages ---
    log "Installing Docker Engine, containerd, and Docker Compose..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

elif [[ "$OS" == "centos" ]]; then
    # --- Uninstall old versions on CentOS ---
    log "Uninstalling old Docker versions..."
    sudo yum remove -y docker \
                      docker-client \
                      docker-client-latest \
                      docker-common \
                      docker-latest \
                      docker-latest-logrotate \
                      docker-logrotate \
                      docker-engine >/dev/null 2>&1 || true

    # --- Set up Docker's yum repository ---
    log "Setting up Docker repository..."
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    # --- Install Docker packages ---
    log "Installing Docker Engine, containerd, and Docker Compose..."
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # --- Start and enable Docker service ---
    log "Starting and enabling Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
else
    log "Unsupported operating system: '$OS'. This script supports Debian, Ubuntu, and CentOS."
    exit 1
fi

# --- Manage Docker as a non-root user (common step) ---
log "Configuring Docker to run without sudo..."
if ! getent group docker >/dev/null; then
    log "Creating 'docker' group..."
    sudo groupadd docker
fi
log "Adding current user '$USER' to the 'docker' group."
sudo usermod -aG docker $USER

log "Docker installation complete!"
log "To apply the new group membership, you must log out and back in, or run 'newgrp docker'."
log "After that, you can verify the installation by running: docker run hello-world" 