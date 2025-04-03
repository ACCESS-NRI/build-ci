#!/bin/bash

if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "This script is meant to be sourced, not executed"
    echo "Usage: . ${BASH_SOURCE[0]}"
    exit 1
fi

# This script enables spack as normal, but also loads and finds the installed
# compilers defined in the build-ci containers/upstream/*/compilers.spack.yaml file.

# See ACCESS-NRI/build-cd: containers/upstream/[dev|prod]/compilers.spack.yaml
upstream_compilers_file="${ENV_COMPILERS_SPACK_MANIFEST:-/opt/compilers.spack.yaml}"

# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/spack-enable.bash"

echo "Loading compilers from $upstream_compilers_file..."
yq '.spack.specs[]' "$upstream_compilers_file" | while read -r compiler; do
  spack load "$compiler" || exit
  spack compiler find
done
echo "Compilers loaded."
