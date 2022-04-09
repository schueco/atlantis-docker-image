FROM alpine:3.15.4 AS downloader
RUN apk --no-cache add unzip~=6 curl~=7

ENV TERRAGRUNT_VERSION=v0.32.4

RUN curl -s -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 && \
    chmod +x terragrunt

FROM runatlantis/atlantis:v0.18.4
# hadolint ignore=DL3018
RUN apk --no-cache add py3-pip

COPY --from=downloader /terragrunt /usr/local/bin/terragrunt

# renovate: datasource=github-releases depName=sgerrand/alpine-pkg-glibc
ENV GLIBC_VERSION=2.31-r0

# Since alpine is not officially supported by aws-cli we need to
# install glibc compatibility for alpine.
# Snippet taken from https://github.com/aws/aws-cli/issues/4685#issuecomment-881965452
# hadolint ignore=DL3018
RUN apk --no-cache add \
        binutils \
        curl \
    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk \
    && apk add --no-cache \
        glibc-${GLIBC_VERSION}.apk \
        glibc-bin-${GLIBC_VERSION}.apk \
    && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
    && rm -rf \
        awscliv2.zip \
        aws \
        /usr/local/aws-cli/v2/*/dist/aws_completer \
        /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/*/dist/awscli/examples \
    && apk --no-cache del \
        binutils \
        curl \
    && rm glibc-${GLIBC_VERSION}.apk \
    && rm glibc-bin-${GLIBC_VERSION}.apk \
    && rm -rf /var/cache/apk/*

ENV ATLANTIS_REPO_CONFIG /etc/atlantis/repos.yaml
ENV TF_INPUT false
COPY run.sh /usr/local/bin/run.sh
RUN chown atlantis:atlantis /usr/local/bin/terragrunt /usr/local/bin/run.sh
ENTRYPOINT [ "run.sh" ]
CMD [ "server" ]
