FROM debian:bullseye-slim

# Set environment variable to suppress interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies including Python, pip, and other utilities
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    git \
    fuse \
    && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /pilot-tester

# Copy the current directory contents into the container
COPY . .

ENV PATH="/opt/conda/bin:$PATH"

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget $MINIFORGE_URL -O /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p /opt/conda && \
    rm -f /tmp/miniforge.sh


# Set default command to run your script
CMD ["bash", "./start-pilot.sh"]
