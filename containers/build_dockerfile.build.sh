DOCKER_BUILDKIT=1 \
  docker build \
  --build-arg PACKAGE="acct" \
  --build-arg COMPILER_PACKAGE="intel-oneapi-compilers" \
  --build-arg COMPILER_NAME="intel" \
  --build-arg COMPILER_VERSION="2021.1.2" \
  --build-arg BASE_IMAGE="base-spack:latest" \
  -f Dockerfile.build \
  -t build \
  . \
