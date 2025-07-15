# Container Resources and Infrastructure

This folder contains the resources required to create the images used by both the custom `build-ci` runners, and developers who want to run containerised `spack` on their own machines.

## Overview

This folder contains the `Dockerfile` and `compose.*.yaml` files needed to build the images.

Furthermore, those images download upstream compilers and common packages informed by the `upstream/[dev|prod]/[packages|compilers].spack.yaml` spack manifests.

Finally, there is a `spack-config` folder that contains a customised [spack-enable.bash](https://github.com/ACCESS-NRI/spack-config/blob/main/spack-enable.bash) used to load `spack`, as well as upstream compilers.

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

Users can modify `SPACK_PACKAGES_REPO_VERSION`/`SPACK_CONFIG_REPO_VERSION`, among other things, from within the docker compose file before running `docker compose build`.
