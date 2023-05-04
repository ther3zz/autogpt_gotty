#version4
ARG GOTTY_VERSION=v1.5.0

# Some parts copied from https://github.com/claytondukes/autogpt-docker/blob/main/Dockerfile
FROM debian:stable AS builder

ARG GOTTY_VERSION

WORKDIR /build

#grab gotty
ADD https://github.com/sorenisanerd/gotty/releases/download/${GOTTY_VERSION}/gotty_${GOTTY_VERSION}_linux_arm64.tar.gz gotty-aarch64.tar.gz
ADD https://github.com/sorenisanerd/gotty/releases/download/${GOTTY_VERSION}/gotty_${GOTTY_VERSION}_linux_amd64.tar.gz gotty-x86_64.tar.gz

#unzip gotty
RUN tar -xzvf "gotty-$(uname -m).tar.gz"

#install git for builder
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get -y install git

#Clone Auto-GPT github
RUN git clone -b stable https://github.com/Significant-Gravitas/Auto-GPT.git






# Use an official Python base image from the Docker Hub
FROM python:3.10-slim

#Copy gotty from builder
COPY --chmod=+x --from=builder /build/gotty /bin/gotty

# Install Firefox / Chromium
RUN apt-get update && apt-get install -y \
    chromium-driver firefox-esr \
    ca-certificates
	
# Install utilities
RUN apt-get install -y curl jq wget git	

# Set environment variables
ENV PIP_NO_CACHE_DIR=yes \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    COMMAND_LINE_PARAMS=${COMMAND_LINE_PARAMS}


# Install the required python packages globally
ENV PATH="$PATH:/root/.local/bin"
COPY requirements.txt .

# Copy the requirements.txt file and install the requirements
COPY --chown=appuser:appuser requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --user -r requirements.txt




# Copy the application files
WORKDIR /app
COPY --from=builder /build/Auto-GPT/ /app


EXPOSE 8080


# Set the entrypoint
WORKDIR /app
CMD ["gotty", "--port", "8080", "--permit-write", "--title-format", "AutoGPT Terminal", "bash", "-c", "python -m autogpt ${COMMAND_LINE_PARAMS}"]
