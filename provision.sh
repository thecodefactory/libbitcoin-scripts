#!/bin/bash
set -e

CC="gcc"
CXX="g++"
BRANCH="master"
UNRECOGNIZED=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--branch)
      shift
      BRANCH="$1"
      shift
      ;;
    *)
      UNRECOGNIZED+=("$1")
      shift
      ;;
  esac
done

# verify no excess arguments
if [[ ${#UNRECOGNIZED[@]} -ne 0 ]]; then
  echo "Error: Unrecognized argument(s) '${UNRECOGNIZED[@]}'."
  exit 1
fi

# assumed directory structure encoded here
pushd "${BRANCH}/source"

SRC_DIR="$(pwd)"
PREFIX=$(dirname "$(pwd)")/install
OBJ_DIR=$(dirname "$(pwd)")/obj

CC="${CC}" CXX="${CXX}" ./libbitcoin-server/builds/gnu/install-gnu.sh \
  --prefix="${PREFIX}" \
  --build-src-dir="${SRC_DIR}" \
  --build-obj-dir="${OBJ_DIR}" \
  --build-use-local-src \
  --build-link=static \
  --build-config=release \
  --build-skip-tests \
  --hardware-optimized \
  --noninteractive

popd # source
