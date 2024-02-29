#!/bin/bash

set -eu

# Get the root of the cloned GSI directory
readonly DIR_ROOT=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )/.." && pwd -P)

# User Options
BUILD_TYPE=${BUILD_TYPE:-"Release"}
CMAKE_OPTS=${CMAKE_OPTS:-}
COMPILER=${COMPILER:-"intel"}		# intel | gnu
BUILD_DIR=${BUILD_DIR:-"${DIR_ROOT}/build"}
INSTALL_PREFIX=${INSTALL_PREFIX:-"${DIR_ROOT}/install"}

#==============================================================================#

# Detect machine (sets MACHINE_ID)
source $DIR_ROOT/ush/detect_machine.sh
echo "MACHINE_ID = $MACHINE_ID"

# Load modules
source $DIR_ROOT/ush/module-setup.sh

module use $DIR_ROOT/modulefiles
module load $MACHINE_ID.$COMPILER
module list

# Collect BUILD Options
CMAKE_OPTS+=" -DBUILD_UTIL_ALLMON=ON"

# Build type for executables
CMAKE_OPTS+=" -DCMAKE_BUILD_TYPE=$BUILD_TYPE"

# Install destination for built executables, libraries, CMake Package config
CMAKE_OPTS+=" -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX"

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR && cd $BUILD_DIR

# Configure, build, install
set -x
cmake $CMAKE_OPTS $DIR_ROOT

make VERBOSE=${BUILD_VERBOSE:-}
make install
set +x

exit
