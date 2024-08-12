#!/bin/bash

# usage: ./setup-spack-envs <models string>

PACKAGES="${1}"

for PACKAGE in ${PACKAGES}; do
  spack env create ${PACKAGE}
  spack env activate ${PACKAGE}
  spack -d install -j 4 --add --fail-fast ${ENV_COMPILER_PKG_NAME}@${ENV_COMPILER_PKG_VERSION} target=${ENV_SPACK_TARGET}
  spack load ${ENV_COMPILER_PKG_NAME}@${ENV_COMPILER_PKG_VERSION} target=${ENV_SPACK_TARGET}
  spack compiler find --scope env:${PACKAGE}
  spack -d install -j 4 --add --only dependencies --fail-fast ${PACKAGE}%${ENV_COMPILER_NAME}@${ENV_COMPILER_VERSION} target=${ENV_SPACK_TARGET}
  # Push any uncached binaries to buildcache
  spack -d buildcache push s3_buildcache "$(spack find --json | jq --raw-output '.[] | (.name + "/" + .hash)')"
  spack env deactivate
done
