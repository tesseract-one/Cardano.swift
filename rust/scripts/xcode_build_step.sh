#!/bin/bash
set -e

MODULE_NAME="CCardano"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HAS_CARGO_IN_PATH=`command -v cargo >/dev/null 2>&1; echo $?`

if [ "${HAS_CARGO_IN_PATH}" -ne "0" ]; then
    source $HOME/.cargo/env
fi

ROOT_DIR="${PODS_TARGET_SRCROOT}/rust"
OUTPUT_DIR=`echo "${CONFIGURATION}" | tr '[:upper:]' '[:lower:]'`

cd "${ROOT_DIR}"

cargo lipo --xcode-integ

mkdir -p "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"

cp -f "${ROOT_DIR}"/target/universal/"${OUTPUT_DIR}"/*.a "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"/
cp -rf "${ROOT_DIR}"/target/include/ "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"/
cp -f "${SCRIPT_DIR}"/module.modulemap "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"/

exit 0
