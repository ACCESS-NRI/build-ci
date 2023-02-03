# ACCESS-NRI model build CI repository
A central repository for reusable CI build testing containers and pipelines used across ACCESS-NRI supported projects.

## Directory structure
### `.github/workflows`
Reusable github workflows for CI builds.
Note: ufortunately github currently disallows subdirectories in `.github/workflows`.

#### `build-and-push-image.yml`
Build and push a Docker image to a specified container repository.

Inputs:
* `container-registry`: The container registry base URL (e.g.: `ghcr.io`)
* `container-path`: The container path inside the registry (e.g. `access-nri/example-image`)
* `dockerfile-directory`: The directory in the caller repository where the Dockerfile is located (e.g. `ci`)

#### `build-package.yml`
Build a specified spack package given a Docker build image.

Inputs:
* `container-registry`: The container registry base URL (e.g.: `ghcr.io`)
* `container-path`: The container path inside the registry (e.g. `access-nri/example-image`)
* `package-name`: The name of the spack package to be built (e.g. `access.nri.oasis3-mct`)

## Usage
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
```

See [Reusing workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows#calling-a-reusable-workflow) for more info.
