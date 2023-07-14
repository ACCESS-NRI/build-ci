A central repository for reusable CI compilation testing workflows and containers used across ACCESS-NRI supported projects.

This repository is also responsible for building Docker images used for CI compilation testing.

# Building CI Docker images

## Actions
### build-and-push-image-base-spack.yml

Builds and pushes the base Spack image used across CI compilation testing images. See Dockerfile at `containers/Dockerfile.base-spack`. Sets up base Linux image; installs and bootstraps Spack.

### build-and-push-image-build.yml

Builds and pushes the compilation testing images for all packages specified in the workflow file. See Dockerfile at `containers/Dockerfile.build`. Uses base Spack image; installs dependencies required for the specified package build.

## Usage
Using Github CLI:

```
gh workflow run build-and-push-image-base-spack.yml
gh workflow run build-and-push-image-base-spack.yml -f spack-packages-version=v1.0.1
gh workflow run build-and-push-image-build.yml
```

Note the base Spack image must be built before running `build-and-push-image-build.yml`.

# Reusable workflows

## `build-package.yml`
Build the specified Spack package given a Docker build image.

Inputs:
* `container-registry`: The container registry base URL (e.g.: `ghcr.io`)
* `container-name`: The container tag (e.g. `access-nri/example-image`)
* `package-name`: The name of the spack package to be built (e.g. `access.nri.oasis3-mct`)
* `compiler-name`: The name of the compiler to use
* `compiler-version`: The version of the compiler to use
* `spack-packages-version`: Optional, defaults to `main`. The git tag or branch for the `ACCESS-NRI/spack_packages` repository. 

### Usage
To use, modify the following .yml file and add to your target repository in the `.github/workflows/` directory:

`.github/workflows/workflow.yml`:

```
name: Example package build testing workflow

on:
  workflow_dispatch:
  pull_request:
  push:
    branches:
      - master

jobs:
  build:
    uses: access-nri/workflows/.github/workflows/build-package.yml@main
    with:
      container-registry: ghcr.io
      container-name: access-nri/build-${{ github.event.repository.name }}-intel2021.1.2
      package-name: [your package name]
      compiler-name: intel
      compiler-version: 2021.1.2
      spack-packages-version: main # this doesn't need to be specified, defaults to main
    permissions:
      packages: read
```

See [Reusing workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows#calling-a-reusable-workflow) for more info.
