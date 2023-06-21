FROM alpine:3.18.2 AS downloader
RUN apk --no-cache add curl~=8

# renovate: datasource=github-releases depName=gruntwork-io/terragrunt
ENV TERRAGRUNT_VERSION=v0.45.2

RUN curl -s -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 && \
    chmod +x terragrunt

# Since alpine is not officially supported by aws-cli we need to
# build it ourselves.
# Snippet taken from https://github.com/aws/aws-cli/issues/4685#issuecomment-1094307056
FROM python:3.11-alpine as installer

# hadolint ignore=DL3018
RUN set -ex; \
    apk add --no-cache \
    git \
    build-base \
    cmake

# renovate: datasource=github-tags depName=aws/aws-cli
ENV AWS_CLI_VERSION=2.11.15
# hadolint ignore=DL3003,SC1091
RUN set -eux; \
    mkdir /aws; \
    git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git /aws; \
    cd /aws; \
    ./configure --with-install-type=portable-exe --with-download-deps; \
    make;

FROM alpine:3.18.2 AS atlantis-config-installer

# renovate: datasource=github-releases depName=transcend-io/terragrunt-atlantis-config
ENV TERRAGRUNT_ATLANTIS_CONFIG_VERSION=v1.16.0

# hadolint ignore=SC3057
RUN wget -q "https://github.com/transcend-io/terragrunt-atlantis-config/releases/download/${TERRAGRUNT_ATLANTIS_CONFIG_VERSION}/terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_amd64.tar.gz" && \
    tar -xzvf terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_amd64.tar.gz && \
    mv terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_amd64/terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_amd64 /terragrunt-atlantis-config

FROM ghcr.io/runatlantis/atlantis:v0.24.3
COPY --from=downloader /terragrunt /usr/local/bin/terragrunt
COPY --from=installer /aws/build/exe/aws /aws/
COPY --from=atlantis-config-installer /terragrunt-atlantis-config /usr/local/bin/terragrunt-atlantis-config

RUN ./aws/install --bin-dir /usr/bin

ENV ATLANTIS_REPO_CONFIG /etc/atlantis/repos.yaml
ENV TF_INPUT false
RUN chown atlantis:atlantis /usr/local/bin/terragrunt
