#!/bin/bash

set -xeo pipefail

if [ -z "${GITLAB_READ_REPOSITORY_TOKEN}" ]; then
    echo "Required environment variable \"GITLAB_READ_REPOSITORY_TOKEN\" is not set. Exiting..."
    exit 1
fi

cat << EOF > /home/atlantis/.gitconfig
[url "https://oauth2:${GITLAB_READ_REPOSITORY_TOKEN}@gitlab.com/"]
    insteadOf = git@gitlab.com:
    insteadOf = ssh://git@gitlab.com/
EOF
exec docker-entrypoint.sh "$@"
