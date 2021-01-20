FROM alpine:3.11.3 AS downloader
RUN apk --no-cache add unzip~=6 curl~=7

ENV KEYCLOAK_PROVIDER_VERSION 1.20.0
ENV TERRAGRUNT_VERSION=v0.26.7

RUN curl -s -Lo terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 && \
    chmod +x terragrunt

RUN \
 # Download the binary and checksum
 echo "Downloading release ${KEYCLOAK_PROVIDER_VERSION}" \
 && curl -OLSs "https://github.com/mrparkers/terraform-provider-keycloak/releases/download/${KEYCLOAK_PROVIDER_VERSION}/terraform-provider-keycloak_v${KEYCLOAK_PROVIDER_VERSION}_linux_amd64_static.zip" \
 && curl -OLSs "https://github.com/mrparkers/terraform-provider-keycloak/releases/download/${KEYCLOAK_PROVIDER_VERSION}/SHA256SUMS" \
 # Verify the SHASUM matches the binary.
 && echo "Verifiying SHASUM" \
 && grep terraform-provider-keycloak_v${KEYCLOAK_PROVIDER_VERSION}_linux_amd64_static.zip SHA256SUMS > keycloak_provider_SHA256SUMS \
 && sha256sum -c keycloak_provider_SHA256SUMS \
 && echo "Unzipping binary" \
 && unzip -oj terraform-provider-keycloak_v${KEYCLOAK_PROVIDER_VERSION}_linux_amd64_static.zip \
 && echo "Set binary as executable" \
 && chmod a+x terraform-provider-keycloak_v${KEYCLOAK_PROVIDER_VERSION} \
 # Clean up
 && echo "Cleaning up" \
 && rm -rf "SHA256SUMS" "keycloak_provider_SHA256SUMS" "terraform-provider-keycloak_v${KEYCLOAK_PROVIDER_VERSION}_linux_amd64_static.zip" "LICENSE"


FROM runatlantis/atlantis:v0.16.0
# hadolint ignore=DL3018
RUN apk --no-cache add py3-pip

COPY --from=downloader /terraform-provider-keycloak* /home/atlantis/.terraform.d/plugins/
COPY --from=downloader /terragrunt /usr/local/bin/terragrunt

ENV ATLANTIS_REPO_CONFIG /etc/atlantis/repos.yaml
ENV TF_INPUT false
COPY repos.yaml /etc/atlantis/repos.yaml
COPY run.sh /usr/local/bin/run.sh
RUN chown atlantis:atlantis /usr/local/bin/terragrunt /usr/local/bin/run.sh
ENTRYPOINT [ "run.sh" ]
CMD [ "server" ]
