FROM debian:bullseye-slim

# Set environment variable to suppress interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies including Python, pip, and other utilities
RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    curl \
    wget \
    git \
    fuse \
    && \
    rm -rf /var/lib/apt/lists/*

# Create a symlink for python to ensure compatibility
RUN ln -s /usr/bin/python3 /usr/bin/python

# Set working directory
WORKDIR /pilot-tester

# Copy the current directory contents into the container
COPY . .

# Make the script executable
RUN chmod +x start-pilot.sh

# Set default command to run your script
CMD ["bash", "./start-pilot.sh"]
