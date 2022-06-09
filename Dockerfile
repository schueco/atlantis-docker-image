FROM alpine:3.16.0 AS downloader
RUN apk --no-cache add unzip~=6 curl~=7

ENV TERRAGRUNT_VERSION=v0.37.2

RUN curl -s -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 && \
    chmod +x terragrunt

FROM ghcr.io/runatlantis/atlantis:v0.19.4
COPY --from=downloader /terragrunt /usr/local/bin/terragrunt

# Since alpine is not officially supported by aws-cli we need to
# build it ourselves.
# Snippet taken from https://github.com/aws/aws-cli/issues/4685#issuecomment-1094307056
# renovate: datasource=github-releases depName=sgerrand/alpine-pkg-glibc
ENV GLIBC_VER=2.35-r0
# hadolint ignore=DL3018
RUN apk add --update --no-cache \
  groff

# hadolint ignore=DL3018
RUN apk del gcompat \
    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
    && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && apk add --update --no-cache util-linux openssl python3 glibc-${GLIBC_VER}.apk glibc-bin-${GLIBC_VER}.apk \
    && unzip awscliv2.zip && aws/install \
    && rm -rf awscliv2.zip aws glibc-${GLIBC_VER}.apk glibc-bin-${GLIBC_VER}.apk \
        /usr/local/aws-cli/v2/*/dist/aws_completer \
        /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/*/dist/awscli/examples \
        /var/cache/apk/*00

# hadolint ignore=DL3018
RUN apk add --no-cache gcompat

ENV ATLANTIS_REPO_CONFIG /etc/atlantis/repos.yaml
ENV TF_INPUT false
COPY run.sh /usr/local/bin/run.sh
RUN chown atlantis:atlantis /usr/local/bin/terragrunt /usr/local/bin/run.sh
ENTRYPOINT [ "run.sh" ]
CMD [ "server" ]
