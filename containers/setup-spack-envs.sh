#!/bin/bash

# usage: ./setup-spack-envs <models string>

PACKAGES="${1}"

for PACKAGE in ${PACKAGES}; do
  spack env create ${PACKAGE}
  spack env activate ${PACKAGE}
  spack -d install -j 4 --add --fail-fast ${ENV_COMPILER_PKG_NAME}@${ENV_COMPILER_PKG_VERSION} arch=${ENV_SPACK_ARCH}
  spack load ${ENV_COMPILER_PKG_NAME}@${ENV_COMPILER_PKG_VERSION} arch=${ENV_SPACK_ARCH}
  spack compiler find --scope env:${PACKAGE}
  spack -d install -j 4 --add --only dependencies --fail-fast ${PACKAGE}%${ENV_COMPILER_NAME}@${ENV_COMPILER_VERSION} arch=${ENV_SPACK_ARCH}
  spack env deactivate
done
