#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

VERSION="$(cat version.txt)"
REPO_NAME="darlinghq/darling-swift"
TAG_NAME="v${VERSION}"
FILE_NAME="swift-${VERSION}.zip"
URL="https://github.com/${REPO_NAME}/releases/download/${TAG_NAME}/${FILE_NAME}"

curl -s "${URL}" -o "${SCRIPT_DIR}/${FILE_NAME}" -L
unzip "${SCRIPT_DIR}/${FILE_NAME}" -d "${SCRIPT_DIR}"
