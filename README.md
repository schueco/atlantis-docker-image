# atlantis-docker

Builds our atlantis image containing terragrunt.
Adds the [terragrunt](https://github.com/gruntwork-io/terragrunt) binary to the [official atlantis image](https://github.com/runatlantis/atlantis)

## Access to private repositories

Pass a [Gitlab access token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) when running the container using the environment variable `GITLAB_READ_REPOSITORY_TOKEN`.
