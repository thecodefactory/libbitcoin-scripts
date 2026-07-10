#!/bin/bash

set -e

# Get list of project repos
projects=$(cat projects)

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
optimization_map["avx2"]="--enable-avx2"
optimization_map["avx512"]="--enable-avx512"
optimization_map["sse4_1"]="--enable-sse41"
optimization_map["sha_ni"]="--enable-shani"

declare -A optimization_flag_map
optimization_flag_map["avx2"]="-mavx2"
optimization_flag_map["avx512"]="-mavx512"
optimization_flag_map["sse4_1"]="-msse4.1"
optimization_flag_map["sha_ni"]="-msha"

OPTIMIZATIONS=""
OPTIMIZATION_FLAGS=""

optimization_flags_all="avx2 avx512 sha_ni sse4_1"
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

# ignore shellcheck 2086 for last usage of ${OPTIMIZATIONS}
#shellcheck disable="SC2086"

for project in ${projects}; do
    pushd "${project}/builds/gnu" > /dev/null
    set +e

    if [ -f autogen.sh ]; then
        bash autogen.sh
    fi
    aclocal
    autoconf
    autoreconf -i
    automake --add-missing
    automake
    make clean
    set -e

    CC=gcc CXX=g++ CFLAGS=${OPTIMIZATION_FLAGS} CXXFLAGS=${OPTIMIZATION_FLAGS} PKG_CONFIG_PATH="${install_dir}/lib/pkgconfig" BOOST_ROOT="${install_dir}" ./configure --with-tests --with-examples --with-pkgconfigdir="${install_dir}/lib/pkgconfig" --prefix="${install_dir}" --with-boost="${install_dir}" --with-icu --with-qrencode --with-png --with-ultrafast --enable-static --disable-shared ${OPTIMIZATIONS}

    make -j "${PARALLEL}"
    make install
    popd > /dev/null # project
done

popd # source

# RUN ./build.sh
