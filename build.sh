#!/bin/bash

# This script sets up the development environment based on the provided Dockerfile.
# It is intended for Debian-based systems (like Ubuntu) and requires sudo privileges for package installation.

set -e # Exit immediately if a command exits with a non-zero status.

# Helper for logging
log() {
    echo ">>> ${*}"
}

# --- Install essential dev tools ---
log "Updating package list and installing essential development tools..."
sudo apt-get update
sudo apt-get install -y \
    gcc-riscv64-unknown-elf gdb-multiarch \
    git python3 python3-dev curl cmake wget clang tmux vim \
    build-essential

# --- Install pip ---
log "Installing pip for Python 3..."
if command -v pip3 &>/dev/null; then
    log "pip3 is already installed."
else
    curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo python3 get-pip.py
    rm get-pip.py
fi

# --- Install Rust ---
log "Installing or updating Rust..."
RUST_VERSION=${1:-nightly} # Allow passing version as first argument, otherwise default to nightly

if ! command -v rustup &> /dev/null; then
    log "Installing rustup..."
    # Install rustup without modifying PATH automatically.
    # We'll source the env file manually and instruct the user.
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
        -y --default-toolchain ${RUST_VERSION} --no-modify-path
    
    # Add cargo to path for this session
    source "$HOME/.cargo/env"
    
    echo
    log "Rustup has been installed but the PATH is not configured for new shells."
    log "To configure your current shell, run 'source \$HOME/.cargo/env'"
    log "For future sessions, add 'source \$HOME/.cargo/env' to your shell profile (e.g., ~/.bashrc)."
    echo
else
    log "Rustup is already installed."
fi

# Set path for the current script in case it wasn't already set
export PATH="$HOME/.cargo/bin:${PATH}"

log "Setting default Rust toolchain to ${RUST_VERSION}..."
rustup default ${RUST_VERSION}

log "Adding RISC-V target..."
rustup target add riscv64imac-unknown-none-elf

log "Installing cargo-binutils..."
cargo install cargo-binutils

log "Adding llvm-tools-preview and rust-src components..."
rustup component add llvm-tools-preview
rustup component add rust-src

log "Environment setup complete!"
log "Please restart your shell or run 'source \$HOME/.cargo/env' to use the Rust toolchain." 