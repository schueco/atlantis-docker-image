# atlantis-docker

Builds our atlantis image containing terragrunt.
Adds the [terragrunt](https://github.com/gruntwork-io/terragrunt) and [aws-cli](https://aws.amazon.com/cli/) binaries to the [official atlantis image](https://github.com/runatlantis/atlantis)

> [!NOTE]  
> This image is built as a multi-arch image for `amd64` and `arm64`.
> We set up a stage for each platform in the Dockerfile and updated the `docker/setup-buildx-action` and `docker/build-push-action` accordingly.
> To build locally, you might need to set up a multi-arch builder for docker buildx.
