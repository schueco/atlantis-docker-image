FROM alpine:3.19.1 AS downloader
RUN apk --no-cache add curl~=8

# renovate: datasource=github-releases depName=gruntwork-io/terragrunt
ENV TERRAGRUNT_VERSION=v0.48.1

RUN curl -s -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 && \
    chmod +x terragrunt

FROM alpine:3.19.1 AS atlantis-config-installer

# renovate: datasource=github-releases depName=transcend-io/terragrunt-atlantis-config
ENV TERRAGRUNT_ATLANTIS_CONFIG_VERSION=v1.16.0

# hadolint ignore=SC3057
RUN wget -q "https://github.com/transcend-io/terragrunt-atlantis-config/releases/download/${TERRAGRUNT_ATLANTIS_CONFIG_VERSION}/terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_amd64.tar.gz" && \
    tar -xzvf terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_amd64.tar.gz && \
    mv terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_amd64/terragrunt-atlantis-config_${TERRAGRUNT_ATLANTIS_CONFIG_VERSION:1}_linux_amd64 /terragrunt-atlantis-config

FROM ghcr.io/runatlantis/atlantis:v0.27.2
COPY --from=downloader /terragrunt /usr/local/bin/terragrunt
COPY --from=atlantis-config-installer /terragrunt-atlantis-config /usr/local/bin/terragrunt-atlantis-config

USER root
# renovate: datasource=repology depName=alpine_3_19/awscli versioning=loose
ENV AWS_CLI_VERSION=2.13.25-r0
RUN apk add --no-cache aws-cli="${AWS_CLI_VERSION}"

ENV ATLANTIS_REPO_CONFIG /etc/atlantis/repos.yaml
ENV TF_INPUT false
RUN chown atlantis:atlantis /usr/local/bin/terragrunt
USER atlantis
