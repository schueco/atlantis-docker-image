FROM alpine:3.18.2 AS downloader
RUN apk --no-cache add curl~=8

# renovate: datasource=github-releases depName=gruntwork-io/terragrunt
ENV TERRAGRUNT_VERSION=v0.45.2

RUN curl -s -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 && \
    chmod +x terragrunt

FROM python:3.11-alpine as installer

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

WORKDIR /aws

# renovate: datasource=github-tags depName=aws/aws-cli
ENV AWS_CLI_VERSION=2.12.6

# Installation process adapted from
# https://github.com/aws/aws-cli/issues/4685#issuecomment-1483496782
# hadolint ignore=DL3018
RUN apk add --no-cache \
  curl~=8 \
  make~=4 \
  cmake~=3 \
  gcc~=12 \
  g++~=12 \
  libc-dev~=0.7 \
  libffi-dev~=3 \
  openssl-dev~=3 \
  \
  && curl https://awscli.amazonaws.com/awscli-${AWS_CLI_VERSION}.tar.gz | tar -xz --strip-components 1 \
  && ./configure --with-download-deps --with-install-type=portable-exe \
  && make && make install \
  \
  && rm -rf \
  /usr/local/lib/aws-cli/aws_completer \
  /usr/local/lib/aws-cli/awscli/data/ac.index \
  /usr/local/lib/aws-cli/awscli/examples && \
  find /usr/local/lib/aws-cli/awscli/data -name 'completions-1*.json' -delete && \
  find /usr/local/lib/aws-cli/awscli/botocore/data -name 'examples-1.json' -delete

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
