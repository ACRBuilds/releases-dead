#!/bin/bash

export my_dir=$(pwd)

echo "Loading configuration..."
source "${my_dir}/${my_txt}"

if [ -z "${GITEA_TOKEN}" ]; then
    echo "Please set GITEA_TOKEN before continuing."
    exit 1
fi

# Email for git
git config --global user.email "${GITHUB_EMAIL}"
git config --global user.name "${GITHUB_USER}"

cd "${ROM_DIR}"

source "${my_dir}/sync.sh"
