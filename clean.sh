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

function trim_darwin() {
    cd .repo/manifests
    cat default.xml | grep -v darwin  > temp && cat temp > default.xml && rm temp
    git commit -a -m "Magic"
    cd ../
    cat manifest.xml | grep -v darwin  > temp && cat temp > manifest.xml && rm temp
    cd ../
}

cd ~

if [ ! -d "${ROM_DIR}" ]; then
mkdir "${ROM_DIR}"
fi
cd "${ROM_DIR}"
if [ -d "${ROM_DIR}/out" ]; then
source build/envsetup.sh
make clean -j$(nproc --all)
make clobber -j$(nproc --all)
fi

if [ ! -d "${ROM_DIR}/.repo" ]; then
echo "Initializing repository..."
repo init -u "${manifest_url}" -b "${branch}" --depth 1
fi
source "${my_dir}"/sync.sh
