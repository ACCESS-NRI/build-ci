# Container Resources and Infrastructure

This folder contains the resources required to create the images used by both the custom `build-ci` runners, and developers who want to run containerised `spack` on their own machines.

## Overview

This folder contains the `Dockerfile` and `compose.yaml` files needed to build the images.

Furthermore, those images download upstream compilers and common packages informed by the `upstream/[packages|compilers].spack.yaml` spack manifests.

This folder is used to inform the `.github/workflows/containers-ci.yml` file, which builds the images automatically. More info can be found [in the workflows README.md](./../.github/workflows/README.md).

## Using Pre-built Images

Images are automatically built and pushed to the [GitHub Container Registry (GHCR)](https://github.com/orgs/ACCESS-NRI/packages?tab=packages&q=build-ci-) when a new version of `build-ci` is released (i.e. on push to `v*` branches). The two published images are:

| Image | Description |
| ----- | ----------- |
| [`ghcr.io/access-nri/build-ci-upstream`](https://github.com/orgs/ACCESS-NRI/packages/container/package/build-ci-upstream) | Contains compilers and common packages pre-installed via spack |
| [`ghcr.io/access-nri/build-ci-runner`](https://github.com/orgs/ACCESS-NRI/packages/container/package/build-ci-runner) | Lightweight spack image that sources compilers and packages from the `upstream` image via a shared volume |

### Image Tags

Images are tagged using the format `<OS>-v<spack-version>-<calver>` (e.g. `rocky-v1.1-2026.04.000`). The `IMAGE_VERSION` in [`containers/.env`](./.env) reflects the currently published version. Available tags can be browsed on the GHCR packages page linked above.

### Running with Docker Compose (Recommended)

The recommended way to use the pre-built images is via `docker compose`, which correctly configures the shared volume between `upstream` and `runner`:

```bash
# Pull the pre-built images (uses IMAGE_VERSION from containers/.env by default)
docker compose -f containers/compose.yaml pull

# Start the services
docker compose -f containers/compose.yaml up --detach

# Open an interactive shell in the runner container
docker compose -f containers/compose.yaml exec runner bash

# Shut down when finished
docker compose -f containers/compose.yaml down --volumes
```

To use a specific image tag, override `IMAGE_VERSION`:

```bash
IMAGE_VERSION=rocky-v1.1-2026.04.000 docker compose -f containers/compose.yaml pull
IMAGE_VERSION=rocky-v1.1-2026.04.000 docker compose -f containers/compose.yaml up --detach
```

> [!NOTE]
> The `runner` image alone does not contain the upstream compilers and packages — these are mounted from the `upstream` image via a shared volume. For direct access to spack with compilers available, use the `upstream` image or the full docker compose setup above.

### Running Standalone

To use the `upstream` image directly (e.g. to access the pre-installed compilers and packages):

```bash
docker pull ghcr.io/access-nri/build-ci-upstream:rocky-v1.1-2026.04.000
docker run -it --rm ghcr.io/access-nri/build-ci-upstream:rocky-v1.1-2026.04.000
```

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
