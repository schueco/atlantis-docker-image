FROM alpine:3.16.2 AS downloader
RUN apk --no-cache add unzip~=6 curl~=7

# renovate:  datasource=github-releases depName=gruntwork-io/terragrunt
ENV TERRAGRUNT_VERSION=v0.38.3

RUN curl -s -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 && \
    chmod +x terragrunt

# Since alpine is not officially supported by aws-cli we need to
# build it ourselves.
# Snippet taken from https://github.com/aws/aws-cli/issues/4685#issuecomment-1094307056
FROM python:3.9-alpine as installer

# hadolint ignore=DL3018
RUN set -ex; \
    apk add --no-cache \
    git unzip groff \
    build-base libffi-dev cmake

# renovate:  datasource=github-tags depName=aws/aws-cli
ENV AWS_CLI_VERSION=2.7.12
# hadolint ignore=DL3003,SC1091
RUN set -eux; \
    mkdir /aws; \
    git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git /aws; \
    cd /aws; \
    sed -i'' 's/PyInstaller.*/PyInstaller==4.10/g' requirements-build.txt; \
    python -m venv venv; \
    . venv/bin/activate; \
    ./scripts/installers/make-exe

FROM ghcr.io/runatlantis/atlantis:v0.19.4
COPY --from=downloader /terragrunt /usr/local/bin/terragrunt
COPY --from=installer /aws/dist/awscli-exe.zip /aws/installer.zip

RUN set -ex; \
    unzip /aws/installer.zip; \
    ./aws/install --bin-dir /usr/bin; \
    aws --version

ENV ATLANTIS_REPO_CONFIG /etc/atlantis/repos.yaml
ENV TF_INPUT false
COPY run.sh /usr/local/bin/run.sh
RUN chown atlantis:atlantis /usr/local/bin/terragrunt /usr/local/bin/run.sh
ENTRYPOINT [ "run.sh" ]
CMD [ "server" ]
