#!/bin/bash
set -e

LIB_NAME="Cardano-Binaries"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}/../.."

cd "${ROOT_DIR}"

TRUNK_VERSION="$(pod trunk info "${LIB_NAME}" | grep -o -E "[0-9]+\.[0-9]+\.[0-9]+" | tail -n 1)"
PODSPEC_VERSION="$(grep -o -E "[0-9]+\.[0-9]+\.[0-9]+" "${LIB_NAME}.podspec")"

if [ "$TRUNK_VERSION" != "$PODSPEC_VERSION" ]; then
  pod trunk push "${LIB_NAME}.podspec"
fi

exit 0
