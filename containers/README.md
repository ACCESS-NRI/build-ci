# Container Resources and Infrastructure

This folder contains the resources required to create the images used by both the custom `build-ci` runners, and developers who want to run containerised `spack` on their own machines.

## Overview

This folder contains the `Dockerfile` and `compose.yaml` files needed to build the images.

Furthermore, those images download upstream compilers and common packages informed by the `upstream/[packages|compilers].spack.yaml` spack manifests.

This folder is used to inform the `.github/workflows/containers-ci.yml` file, which builds the images automatically. More info can be found [in the workflows README.md](./../.github/workflows/README.md).

## How to build `spack` for testing

You can use spack in a similar way to `build-ci`, with it's own upstream `spack` used for compilers and common packages. This is also suitable for developers to test. Run the following Docker Compose commands:

```bash
COMPOSE_BAKE=1 docker compose -f containers/compose.yaml build
docker compose -f containers/compose.yaml up --detach
docker compose -f containers/compose.yaml exec runner bash
```

When finished, you can run the following to shut down the services:

```bash
docker compose -f containers/compose.yaml down --volumes
```

Users can modify the `SPACK_CONFIG_REPO_VERSION`, among other things, from within the docker compose file before running `docker compose build`.

### Alternatives

For a simpler build, one can use the `dev` target in the Dockerfile, built via:

```bash
docker build --no-cache --target=dev --build-arg=OS=rocky --build-arg=SPACK_CONFIG_DIR=/opt/spack-config/v1.1/ci-runner --tag=build-ci-dev containers/
docker run -it --rm build-ci-dev:latest
```

It also allows building of versions that are technically unsupported regarding the version of `build-ci` (eg. `build-ci@v2` for `spack < 0.22`, `build-ci@v3` for `spack >= 1.0`).
