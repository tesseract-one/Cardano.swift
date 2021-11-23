#!/bin/bash
set -e

BUILD_SCRIPT="scripts/build_binary_macos.sh"
BINARIES_DIR="binaries"
OUTPUT_DIR="binaries"
LICENSE="../LICENSE"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="${DIR}/.."

/bin/bash "${ROOT_DIR}/${BUILD_SCRIPT}" "$1"

cd "${ROOT_DIR}/${BINARIES_DIR}"

rm -f "${ROOT_DIR}/${OUTPUT_DIR}"/*.zip

cp -f "${ROOT_DIR}/${LICENSE}" "${ROOT_DIR}/${OUTPUT_DIR}"/

for frmwk in ./*.xcframework; do
  name="${frmwk%.*}"
  ZIP_FILE="${ROOT_DIR}/${OUTPUT_DIR}/${name}.binaries.zip"
  zip -r "${ZIP_FILE}" "${frmwk}" LICENSE
  shasum -a 256 --tag "${ZIP_FILE}"
  swiftsum=$(swift package compute-checksum "${ZIP_FILE}")
  echo "Swift checksum: ${swiftsum}"
done

exit 0
