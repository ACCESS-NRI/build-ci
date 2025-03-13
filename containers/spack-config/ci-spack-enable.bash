#!/bin/bash

if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "This script is meant to be sourced, not executed"
    echo "Usage: . ${BASH_SOURCE[0]}"
    exit 1
fi

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
