FROM ubuntu:22.04
SHELL ["/bin/bash", "-c"]


# install essential dev tools
RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y \
    gcc-riscv64-unknown-elf gdb-multiarch \
    git python3 python3-dev curl cmake git wget clang tmux vim\
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install pip using get-pip.py (more reliable)
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py && \
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple



# install rust
ARG RUST_VERSION=nightly
ENV RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ENV RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
ENV PATH="/root/.cargo/bin:${PATH}"

# Create cargo config for faster downloads
RUN mkdir -p /root/.cargo && \
    echo '[source.crates-io]' > /root/.cargo/config.toml && \
    echo 'replace-with = "ustc"' >> /root/.cargo/config.toml && \
    echo '' >> /root/.cargo/config.toml && \
    echo '[source.ustc]' >> /root/.cargo/config.toml && \
    echo 'registry = "https://mirrors.ustc.edu.cn/crates.io-index"' >> /root/.cargo/config.toml

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    -y --default-toolchain ${RUST_VERSION} --target riscv64imac-unknown-none-elf && \
    cargo install cargo-binutils && \
    rustup component add llvm-tools-preview && \
    rustup component add rust-src

WORKDIR /root/workspace

CMD ["/bin/bash"]

