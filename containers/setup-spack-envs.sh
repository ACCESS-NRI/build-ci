#!/bin/bash

# usage: ./setup-spack-envs <compiler name> <compiler version> <models string>
# eg: 
if [ "$#" -ne 3 ]; then
  exit 1
fi

COMPILER_PACKAGE="$1"
COMPILER_VERSION="$2"
PACKAGES="$3"

for PACKAGE in $PACKAGES; do
  spack env create $PACKAGE
  spack env activate $PACKAGE
  spack -d install -j 4 --add --fail-fast $COMPILER_PACKAGE@$COMPILER_VERSION
  spack load $COMPILER_PACKAGE@$COMPILER_VERSION
  spack compiler find --scope env:$PACKAGE
  spack -d install -j 4 --add --only dependencies --fail-fast $PACKAGE
  spack gc -y
  spack env deactivate
done