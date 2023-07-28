### Building Docker containers for local testing

Ensure the following environment variables are populated:

- S3_ACCESS_KEY_ID
- S3_ACCESS_KEY_SECRET
- BUILDCACHE_KEY_PRIV_PATH
- BUILDCACHE_KEY_PUB_PATH

Then run:

    ./build_dockerfile.base-spack.sh
    ./build_dockerfile.build.sh

To run interactively:

    docker run -it build

To test build:

    spack -d install --only package --no-checksum mom5%intel
