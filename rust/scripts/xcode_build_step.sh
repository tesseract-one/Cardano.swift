#!/bin/bash
set -e

MODULE_NAME="CCardano"
C_LIB_NAME="cardano"

if [[ "${CARDANO_USES_BINARY_RUST_XCFRAMEWORK}" == "YES" ]]; then
  echo "warning: Project already has binary xcframework. Check your target configuration."
  exit 0
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HAS_CARGO_IN_PATH=`command -v cargo >/dev/null 2>&1; echo $?`

if [ "${HAS_CARGO_IN_PATH}" -ne "0" ]; then
    source $HOME/.cargo/env
fi

ROOT_DIR="${PODS_TARGET_SRCROOT}/rust"

if [[ "${CONFIGURATION}" == "Release" ]]; then
  RELEASE="--release"
else
  RELEASE=""
fi

if [[ -n "${DEVELOPER_SDK_DIR:-}" ]]; then
  # Assume we're in Xcode, which means we're probably cross-compiling.
  # In this case, we need to add an extra library search path for build scripts and proc-macros,
  # which run on the host instead of the target.
  # (macOS Big Sur does not have linkable libraries in /usr/lib/.)
  export LIBRARY_PATH="${DEVELOPER_SDK_DIR}/MacOSX.sdk/usr/lib:${LIBRARY_PATH:-}"
fi

function get_platform_triplet() {
  arch="$1"
  if [[ "${arch}" == "arm64" ]]; then
    arch="aarch64"
  fi
  case "${PLATFORM_NAME}" in
    macosx)
      echo "${arch}-apple-darwin"
    ;;
    iphoneos)
      echo "${arch}-apple-ios"
    ;;
    iphonesimulator)
      if [[ "${arch}" == "aarch64" ]]; then
        echo "aarch64-apple-ios-sim"
      else
        echo "${arch}-apple-ios"
      fi
    ;;
    appletvos | appletvsimulator)
      echo "tvOS is unsupported"
      exit 1
    ;;
    watchos | watchsimulator)
      echo "watchOS is unsupported"
      exit 1
    ;;
    *)
      echo "Unknown platform: ${PLATFORM_NAME}"
      exit 1
    ;;
  esac
}

OUTPUT_DIR=`echo "${CONFIGURATION}" | tr '[:upper:]' '[:lower:]'`

cd "${ROOT_DIR}"

BUILT_LIBS=""
for arch in $ARCHS; do
  TTRIPLET=$(get_platform_triplet $arch)
  cargo build --lib $RELEASE --target ${TTRIPLET}
  BUILT_LIBS="${BUILT_LIBS} ${ROOT_DIR}/target/${TTRIPLET}/${OUTPUT_DIR}/lib${C_LIB_NAME}.a"
done

BUILT_LIBS="${BUILT_LIBS:1}"

mkdir -p "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"

lipo ${BUILT_LIBS} -create -output "${CONFIGURATION_BUILD_DIR}/lib${C_LIB_NAME}.a"

cp -rf "${ROOT_DIR}"/target/include/* "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"/
cp -f "${SCRIPT_DIR}"/module.modulemap "${CONFIGURATION_BUILD_DIR}/${MODULE_NAME}"/

exit 0
