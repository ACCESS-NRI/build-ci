#!/bin/bash

# usage: ./setup-spack-envs <compiler package> <compiler name> <compiler version> <models string>
# eg: 
if [ "$#" -ne 4 ]; then
  echo "Invalid number of arguments: expecting 4"
  exit 1
fi

COMPILER_PACKAGE="$1"
COMPILER_NAME="$2"
COMPILER_VERSION="$3"
PACKAGES="$4"

for PACKAGE in $PACKAGES; do
  spack env create $PACKAGE
  spack env activate $PACKAGE
  spack -d install -j 4 --add --fail-fast $COMPILER_PACKAGE@$COMPILER_VERSION
  spack load $COMPILER_PACKAGE@$COMPILER_VERSION
  spack compiler find --scope env:$PACKAGE
  spack -d install -j 4 --add --only dependencies --fail-fast $PACKAGE%$COMPILER_NAME@$COMPILER_VERSION
  spack gc -y
  spack env deactivate
done