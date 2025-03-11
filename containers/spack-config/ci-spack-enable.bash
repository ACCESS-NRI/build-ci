#!/bin/bash

# !!! This is not an executable! Source this file !!!

# This script enables spack as normal, but also loads and finds the installed
# compilers defined in the build-ci containers/config/packages.json file.

# See ACCESS-NRI/build-cd: containers/config/[dev.]packages.json
upstream_packages_file="${ENV_PACKAGES_JSON_FILE:-/opt/packages.json}"

# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/spack-enable.bash"

echo "Loading compilers from $upstream_packages_file..."
# shellcheck disable=SC2046
spack load $(jq -cr '.compilers | join(" ")' "$upstream_packages_file") || exit
echo "Compilers loaded."

echo "Finding compilers..."
spack compiler find || exit
echo "Compilers found."
