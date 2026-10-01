#!/bin/bash

set -e

# Git master/main branch name
branch="master"

if [ ! -z "$1" ]; then
    branch=$1
fi

if [ -z "$PARALLEL" ]; then
    PARALLEL=$(nproc)
fi

# Autodetect optimization flags
# --------------------------------------------------------
declare -A optimization_map
optimization_map["avxifma"]="--enable-avxifma"
optimization_map["avx2"]="--enable-avx2"
optimization_map["avx512"]="--enable-avx512"
optimization_map["avx512ifma"]="--enable-avx512ifma"
optimization_map["sse4_1"]="--enable-sse41"
optimization_map["sha_ni"]="--enable-shani"
optimization_map["aes"]="--enable-aesni"
optimization_map["vaes"]="--enable-vaes"

declare -A optimization_flag_map
#optimization_flag_map["avxifma"]="-mavxifma"
optimization_flag_map["avx2"]="-mavx2"
optimization_flag_map["avx512"]="-mavx512f"
#optimization_flag_map["avx512ifma"]="-mavx512ifma"
optimization_flag_map["sse4_1"]="-msse4.1"
optimization_flag_map["sha_ni"]="-msha"
optimization_flag_map["aes"]="-maes"
optimization_flag_map["vaes"]="-mvaes"

OPTIMIZATIONS=""
OPTIMIZATION_FLAGS=""

optimization_flags_all="avx2 avx512 sse4_1 sha_ni aes vaes"
for flag in ${optimization_flags_all}; do
    if grep -q "$flag" /proc/cpuinfo; then
        OPTIMIZATIONS="${OPTIMIZATIONS} ${optimization_map[${flag}]}"
        OPTIMIZATION_FLAGS="${OPTIMIZATION_FLAGS} ${optimization_flag_map[${flag}]}"
    fi
done

# Trim leading spaces
OPTIMIZATIONS="${OPTIMIZATIONS#"${OPTIMIZATIONS%%[![:space:]]*}"}"
OPTIMIZATION_FLAGS="${OPTIMIZATION_FLAGS#"${OPTIMIZATION_FLAGS%%[![:space:]]*}"}"

echo "Detected optimizations: ${OPTIMIZATIONS}"
echo "Detected optimization flags: ${OPTIMIZATION_FLAGS}"
# --------------------------------------------------------


source=${branch}/source

pushd "${source}"

install_dir=$(dirname "$(pwd)")/install
pushd libbitcoin-server/builds/gnu
rm -rf libbitcoin-node libbitcoin-system secp256k1 boost libbitcoin-database  libbitcoin-server libbitcoin-network UltrafastSecp256k1

# ignore shellcheck 2086 for last usage of ${OPTIMIZATIONS}
#shellcheck disable="SC2086"

CC=gcc CXX=g++ PKG_CONFIG_PATH="${install_dir}/lib/pkgconfig" CFLAGS=${OPTIMIZATION_FLAGS} CXXFLAGS=${OPTIMIZATION_FLAGS} ./install-gnu.sh --prefix="${install_dir}" --with-ultrafast --build-ultrafast --build-boost --build-link=static --build-config=release --build-skip-tests --build-parallel="${PARALLEL}" --noninteractive --build-post-install-clean ${OPTIMIZATIONS}

popd # source

# RUN ./build_server.sh
