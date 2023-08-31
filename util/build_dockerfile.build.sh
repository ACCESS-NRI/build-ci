DOCKER_BUILDKIT=1 \
  docker build \
  --build-arg PACKAGE="mom5" \
  --build-arg COMPILER_PACKAGE="intel-oneapi-compilers" \
  --build-arg COMPILER_NAME="intel" \
  --build-arg COMPILER_VERSION="2021.2.0" \
  --build-arg BASE_IMAGE="base-spack:latest" \
  -f Dockerfile.build \
  -t build \
  $@ \
  . \
