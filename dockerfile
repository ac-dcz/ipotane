FROM ubuntu:22.04
SHELL ["/bin/bash", "-c"]


# install essential dev tools
RUN apt-get update && apt-get install -y \
    gcc-riscv64-unknown-elf gdb-multiarch \
    git python3 python3-dev curl cmake git wget clang tmux vim\
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install pip using get-pip.py (more reliable)
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py



# install rust
ARG RUST_VERSION=nightly
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    -y --default-toolchain ${RUST_VERSION} --target riscv64imac-unknown-none-elf && \
    cargo install cargo-binutils && \
    rustup component add llvm-tools-preview && \
    rustup component add rust-src

WORKDIR /root/workspace

CMD ["/bin/bash"]

