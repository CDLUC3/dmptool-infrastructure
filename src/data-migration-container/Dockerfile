# syntax = docker/dockerfile:1

FROM public.ecr.aws/docker/library/node:22.1.0-alpine3.19

# Install necessary tools and utilities and setup virtual environment to install awscli
RUN apk update && apk add --no-cache \
    bash \
    git \
    curl \
    unzip \
    zip \
    tar \
    docker-cli \
    jq \
    nodejs \
    npm \
    make \
    mysql-client \
    mariadb-connector-c \
    python3 \
    py3-pip \
    && python3 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip install awscli \
    && ln -s /opt/venv/bin/aws /usr/local/bin/aws


# Set working directory
WORKDIR /root

# Default shell bash
CMD ["/bin/bash"]
