# Ensure S3_ACCESS_KEY_ID and S3_ACCESS_KEY_SECRET
# are populated in your local environment before building
# as well as buildcache access private and public keys
# in ./keys/access-nri.*

DOCKER_BUILDKIT=1 \
  docker build \
  --build-arg SPACK_PACKAGES_VERSION="main" \
  --secret id=S3_ACCESS_KEY_ID \
  --secret id=S3_ACCESS_KEY_SECRET \
  --secret id=access-nri.priv,src=./keys/access-nri.priv \
  --secret id=access-nri.pub,src=./keys/access-nri.pub \
  -f Dockerfile.base-spack \
  -t base-spack \
  $@ \
  . \
