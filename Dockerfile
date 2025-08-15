# Simple Dockerfile for STRipy-pipeline
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install minimal dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install ExpansionHunter (core dependency for STR analysis)
ARG EXPANSIONHUNTER_VERSION=5.0.0
RUN wget https://github.com/Illumina/ExpansionHunter/releases/download/v${EXPANSIONHUNTER_VERSION}/ExpansionHunter-v${EXPANSIONHUNTER_VERSION}-linux_x86_64.tar.gz \
    && tar -xzf ExpansionHunter-v${EXPANSIONHUNTER_VERSION}-linux_x86_64.tar.gz \
    && mv ExpansionHunter-v${EXPANSIONHUNTER_VERSION}-linux_x86_64/bin/ExpansionHunter /usr/local/bin/ \
    && rm -rf ExpansionHunter-v${EXPANSIONHUNTER_VERSION}-linux_x86_64*

# Clone STRipy-pipeline repository
RUN git clone https://gitlab.com/andreassh/stripy-pipeline.git /opt/stripy-pipeline

# Set working directory
WORKDIR /opt/stripy-pipeline

# Install Python requirements if they exist
RUN if [ -f requirements.txt ]; then pip3 install -r requirements.txt; fi

# Create data and output directories
RUN mkdir -p /data /output && chmod 755 /data /output

# Set working directory for user data
WORKDIR /data

# Expose volumes
VOLUME ["/data", "/output", "/references"]

# Set entrypoint
ENTRYPOINT ["python3", "/opt/stripy-pipeline/stri.py"]

# Default help command
CMD ["--help"]
