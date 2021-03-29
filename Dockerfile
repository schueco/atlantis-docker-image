FROM alpine:3.13.3 AS downloader
RUN apk --no-cache add unzip~=6 curl~=7

ENV TERRAGRUNT_VERSION=v0.28.17

RUN curl -s -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 && \
    chmod +x terragrunt

FROM runatlantis/atlantis:v0.16.1
# hadolint ignore=DL3018
RUN apk --no-cache add py3-pip

COPY --from=downloader /terragrunt /usr/local/bin/terragrunt

ENV ATLANTIS_REPO_CONFIG /etc/atlantis/repos.yaml
ENV TF_INPUT false
COPY repos.yaml /etc/atlantis/repos.yaml
COPY run.sh /usr/local/bin/run.sh
RUN chown atlantis:atlantis /usr/local/bin/terragrunt /usr/local/bin/run.sh
ENTRYPOINT [ "run.sh" ]
CMD [ "server" ]
