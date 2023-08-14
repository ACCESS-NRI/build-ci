# Ensure the following are populated in your local environment before building
# - S3_ACCESS_KEY_ID
# - S3_ACCESS_KEY_SECRET
# - BUILDCACHE_KEY_PRIV_PATH - path to buildcache private key file
# - BUILDCACHE_KEY_PUB_PATH - path to buildcache public key file

DOCKER_BUILDKIT=1 \
  docker build \
  --build-arg SPACK_PACKAGES_VERSION="main" \
  --secret id=S3_ACCESS_KEY_ID \
  --secret id=S3_ACCESS_KEY_SECRET \
  --secret id=access-nri.priv,src=${BUILDCACHE_KEY_PRIV_PATH} \
  --secret id=access-nri.pub,src=${BUILDCACHE_KEY_PUB_PATH} \
  -f Dockerfile.base-spack \
  -t base-spack \
  $@ \
  . \
