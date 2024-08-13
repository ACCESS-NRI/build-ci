## Requirements

* Build a container using the same OS, `spack`, `spack-packages` and `spack-config` versions as an official release of a product built via Spack. e.g. Rocky Linux 8.10, `spack` `v0.20`, `spack-packages` `2024.03.22`, `spack-config` `2024.03.22`.

* `spack` (branch-based versioning) and `spack-config` (directory-based versioning) are versioned based on the Spack version. Since `spack-packages` is not versioned, we have to use tags, e.g.  `2024.03.22`, to extract an older version that was created to be used with an older version of Spack.

## How to build Docker images

To build an image with defaults:

    docker build -f Dockerfile.base-spack -t <name>:<version> --target dev --no-cache --progress=plain .

To build an image with specific versions of `spack`, `spack-packages` and `spack-config`:

    docker build -f Dockerfile.base-spack -t spack-dev:v0.20 --target dev --build-arg SPACK_VERSION=v0.20 --build-arg SPACK_PACKAGES_REPO_VERSION=2024.03.22 --build-arg SPACK_CONFIG_REPO_VERSION=2024.03.22 --no-cache --progress=plain .

To run:

    docker run -it --rm <name>:<version>
