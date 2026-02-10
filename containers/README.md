# Container Resources and Infrastructure

This folder contains the resources required to create the images used by both the custom `build-ci` runners, and developers who want to run containerised `spack` on their own machines.

## Overview

This folder contains the `Dockerfile` and `compose.*.yaml` files needed to build the images.

Furthermore, those images download upstream compilers and common packages informed by the `upstream/[dev|prod]/[packages|compilers].spack.yaml` spack manifests.

This folder is used to inform the `.github/workflows/containers-ci.yml` file, which builds the images automatically. More info can be found [in the workflows README.md](./../.github/workflows/README.md).

## How to build `spack` for testing

You can use spack in a similar way to `build-ci`, with it's own upstream `spack` used for compilers and common packages. This is also suitable for developers to test. Run the following Docker Compose commands:

```bash
COMPOSE_BAKE=1 docker compose -f containers/compose.dev.yaml build
docker compose -f containers/compose.dev.yaml up --detach
docker compose -f containers/compose.dev.yaml exec runner bash
```

When finished, you can run the following to shut down the services:

```bash
docker compose -f containers/compose.dev.yaml down --volumes
```

Users can modify the `SPACK_CONFIG_REPO_VERSION`, among other things, from within the docker compose file before running `docker compose build`.
