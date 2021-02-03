#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SWIFT_TARGET="CCardano"
RUST_TARGETS="aarch64-apple-ios,x86_64-apple-darwin" # aarch64-apple-darwin,

HAS_CARGO_IN_PATH=`which cargo; echo $?`

if [ "${HAS_CARGO_IN_PATH}" -ne "0" ]; then
    source $HOME/.cargo/env
fi

ROOT_DIR="${DIR}/../rust"
OUTPUT_DIR="${DIR}/../Sources/${SWIFT_TARGET}"

if [ "$1" == "debug" ]; then
  RELEASE=""
  CONFIGURATION="debug"
else
  RELEASE="--release"
  CONFIGURATION="release"
fi

cd "${ROOT_DIR}"

cargo lipo --targets "${RUST_TARGETS}" "${RELEASE}"

mkdir -p "${OUTPUT_DIR}/include"

cp -f "${ROOT_DIR}"/target/universal/"${CONFIGURATION}"/*.a "${OUTPUT_DIR}"/
cp -f "${ROOT_DIR}"/target/include/*.h "${OUTPUT_DIR}"/include/

exit 0
