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

RUN bash Miniforge3.sh -b -p $HOME/miniforge

# Set default command to run your script
CMD ["bash", "./start-pilot.sh"]
