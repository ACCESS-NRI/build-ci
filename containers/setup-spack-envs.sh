#!/bin/bash

# usage: ./setup-spack-envs <models string>

PACKAGES="${1}"

for PACKAGE in ${PACKAGES}; do
  spack env create ${PACKAGE}
  spack env activate ${PACKAGE}
  spack -d install -j 4 --add --fail-fast ${SPACK_ENV_COMPILER_PACKAGE}@${SPACK_ENV_COMPILER_VERSION} arch=${SPACK_ENV_ARCH}
  spack load ${SPACK_ENV_COMPILER_PACKAGE}@${SPACK_ENV_COMPILER_VERSION} arch=${SPACK_ENV_ARCH}
  spack compiler find --scope env:${PACKAGE}
  spack -d install -j 4 --add --only dependencies --fail-fast ${PACKAGE}%${SPACK_ENV_COMPILER_NAME}@${SPACK_ENV_COMPILER_VERSION} arch=${SPACK_ENV_ARCH}
  spack env deactivate
done