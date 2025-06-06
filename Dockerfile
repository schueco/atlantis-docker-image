FROM alpine:3.22.0 AS setup-base
RUN apk --no-cache add curl~=8

# renovate: datasource=github-releases depName=gruntwork-io/terragrunt
ENV TERRAGRUNT_VERSION=v0.80.2

# renovate: datasource=github-releases depName=transcend-io/terragrunt-atlantis-config
ENV TERRAGRUNT_ATLANTIS_CONFIG_VERSION=v1.18.0

# arm64-specific stage
FROM setup-base AS setup-arm64

RUN curl -s -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_arm64 && \
  chmod +x terragrunt

RUN wget -q https://github.com/transcend-io/terragrunt-atlantis-config/releases/download/${TERRAGRUNT_ATLANTIS_CONFIG_VERSION}/terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_arm64 && \
  mv terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_arm64 /terragrunt-atlantis-config && \
  chmod +x terragrunt-atlantis-config

# amd64-specific stage
FROM setup-base AS setup-amd64

RUN curl -s -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 && \
  chmod +x terragrunt

RUN wget -q https://github.com/transcend-io/terragrunt-atlantis-config/releases/download/${TERRAGRUNT_ATLANTIS_CONFIG_VERSION}/terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_amd64 && \
  mv terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_amd64 /terragrunt-atlantis-config && \
  chmod +x terragrunt-atlantis-config

FROM setup-${TARGETARCH} AS cli-setup

# hadolint ignore=SC3057
FROM ghcr.io/runatlantis/atlantis:v0.34.0
COPY --from=cli-setup /terragrunt /usr/local/bin/terragrunt
COPY --from=cli-setup /terragrunt-atlantis-config /usr/local/bin/terragrunt-atlantis-config

USER root
# renovate: datasource=repology depName=alpine_3_19/awscli versioning=loose
ENV AWS_CLI_VERSION=2.22.10-r0
RUN apk add --no-cache \
  aws-cli="${AWS_CLI_VERSION}" \
  jq

ENV ATLANTIS_REPO_CONFIG /etc/atlantis/repos.yaml
ENV TF_INPUT false
RUN chown atlantis:atlantis /usr/local/bin/terragrunt
USER atlantis
