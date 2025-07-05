#!/bin/bash

# This script sets up the development environment based on the provided Dockerfile.
# It supports Debian-based (Ubuntu) and RHEL-based (CentOS) systems.
# It requires sudo privileges for package installation.

set -e # Exit immediately if a command exits with a non-zero status.

# Helper for logging
log() {
    echo ">>> ${*}"
}

# --- OS Detection ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    log "Cannot detect operating system from /etc/os-release. Aborting."
    exit 1
fi

log "Detected OS: $OS"


# --- Install essential dev tools based on OS ---
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    log "Updating package list and installing essential development tools for Debian/Ubuntu..."
    sudo apt-get update
    sudo apt-get install -y \
        gcc-riscv64-unknown-elf gdb-multiarch \
        git python3 python3-dev curl cmake wget clang tmux vim \
        build-essential

elif [[ "$OS" == "centos" ]]; then
    log "Installing essential development tools for CentOS..."
    # 'Development Tools' group contains gcc, make, etc.
    sudo yum groupinstall -y 'Development Tools'
    sudo yum install -y git python3-devel curl cmake wget clang tmux vim

    # The RISC-V toolchain is not in standard CentOS repos. We check and warn the user.
    log "Checking for RISC-V toolchain..."
    if ! command -v riscv64-unknown-elf-gcc &> /dev/null; then
        log "--------------------------------------------------------------------------------"
        log "WARNING: RISC-V GCC toolchain (riscv64-unknown-elf-gcc) not found."
        log "On CentOS/RHEL, this often requires manual installation."
        log "Please download a pre-built toolchain from: https://www.sifive.com/software"
        log "Or build it from source: https://github.com/riscv-collab/riscv-gnu-toolchain"
        log "After installation, ensure the toolchain's 'bin' directory is in your PATH."
        log "--------------------------------------------------------------------------------"
    fi
    if ! command -v gdb-multiarch &> /dev/null; then
        # Check for gdb, which might be sufficient on CentOS if compiled with multi-target support
        if ! command -v gdb &> /dev/null; then
            log "--------------------------------------------------------------------------------"
            log "WARNING: gdb-multiarch / gdb not found."
            log "This may also require manual installation on CentOS/RHEL."
            log "It is often included with the full RISC-V toolchain distribution."
            log "--------------------------------------------------------------------------------"
        else
            log "Found 'gdb'. Assuming it has multi-arch support. If you encounter issues,"
            log "you may need to install a specific 'gdb-multiarch' build."
        fi
    fi
else
    log "Unsupported operating system: '$OS'. This script supports Debian, Ubuntu, and CentOS."
    exit 1
fi


# --- Install pip (OS-agnostic method) ---
log "Installing pip for Python 3..."
if command -v pip3 &>/dev/null; then
    log "pip3 is already installed."
else
    curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo python3 get-pip.py
    rm get-pip.py
fi

# --- Install Rust (OS-agnostic method) ---
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
log "Please review any WARNINGS above for steps that may require manual intervention."
log "Please restart your shell or run 'source \$HOME/.cargo/env' to use the Rust toolchain." 