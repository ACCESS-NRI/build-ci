To build Docker containers, run:

S3_ACCESS_KEY_ID=... S3_ACCESS_KEY_SECRET=... ./build_dockerfile.base-spack.sh
./build_dockerfile.build.sh

To run interactively:

docker run -it build

To test build:

spack -d install --only package --no-checksum mom5%intel
