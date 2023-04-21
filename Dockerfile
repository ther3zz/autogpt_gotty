#version2
ARG GOTTY_VERSION=v1.5.0

# Copied from https://github.com/claytondukes/autogpt-docker/blob/main/Dockerfile
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

COPY --chmod=+x --from=builder /build/gotty /bin/gotty

# Install git
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get -y install git chromium-driver






# Install Xvfb and other dependencies for headless browser testing
RUN apt-get update \
    && apt-get install -y wget gnupg2 libgtk-3-0 libdbus-glib-1-2 dbus-x11 xvfb ca-certificates

# Install Firefox / Chromium
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y chromium firefox-esr

# Set environment variables
ENV PIP_NO_CACHE_DIR=yes \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    COMMAND_LINE_PARAMS=${COMMAND_LINE_PARAMS}

# Create a non-root user and set permissions
RUN useradd --create-home appuser
WORKDIR /home/appuser
RUN chown appuser:appuser /home/appuser
USER appuser

# Copy the requirements.txt file and install the requirements
COPY --chown=appuser:appuser requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --user -r requirements.txt




# Copy the application files
# COPY --chown=appuser:appuser /autogpt	 ./autogpt
WORKDIR /autogpt
COPY --from=builder --chown=appuser:appuser /build/Auto-GPT/ /home/appuser/



EXPOSE 8080


# Set the entrypoint
WORKDIR /home/appuser
#ENTRYPOINT ["python", "-m", "autogpt"]
CMD ["gotty", "--port", "8080", "--permit-write", "--title-format", "AutoGPT Terminal", "bash", "-c", "python -m autogpt ${COMMAND_LINE_PARAMS}"]
