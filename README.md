A central repository for reusable CI compilation testing containers and pipelines used across ACCESS-NRI supported projects.

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
gh workflow run build-and-push-image-build.yml
```

Note the base-spack image must be built before running the build-and-push-image-build.yml.

# Using reusable workflows

## Workflow overviews

### `build-package.yml`
Build the specified Spack package given a Docker build image.

Inputs:
* `container-registry`: The container registry base URL (e.g.: `ghcr.io`)
* `container-name`: The container tag (e.g. `access-nri/example-image`)
* `package-name`: The name of the spack package to be built (e.g. `access.nri.oasis3-mct`)
* `compiler-name`: The name of the compiler to use
* `compiler-version`: The version of the compiler to use

### `build-and-push-image.yml`
Build and push a Docker image to a specified container repository.

Inputs:
* `container-registry`: The container registry base URL (e.g.: `ghcr.io`)
* `container-name`: The container tag (e.g. `access-nri/example-image`)
* `dockerfile-directory`: The directory in the caller repository where the Dockerfile is located (e.g. `ci`)
* `dockerfile-name`: Name of the Dockerfile to use (e.g. `Dockerfile.base-spack`)

## Usage
To use a reusable workflow, add the following yml file your target repository in the `.github/workflows/` directory. You will then be able to run it from the "Actions" tab on the repository page or via the Github CLI.

### Simple example
`.github/workflows/workflow.yml`:

```
name: Example workflow

on:
  workflow_dispatch:
  pull_request:
  push:
    branches:
      - main

jobs:
  reusable-workflow-job:
    uses: access-nri/workflows/.github/workflows/example-workflow.yml@main
    with:
      container-registry: ghcr.io
      container-path: access-nri/example-image
      dockerfile-directory: ci
      dockerfile-name: Dockerfile.example
```

See [Reusing workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows#calling-a-reusable-workflow) for more info.
