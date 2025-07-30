# build-ci

A central repository for reusable CI compilation testing workflows and containers used across ACCESS-NRI supported projects.

## Repositories Serviced By `build-ci`

These are repositories that use the `component` tag, which can be given by either this [search url](https://github.com/search?q=org%3AACCESS-NRI%20topic%3Abuild-ci-enabled&type=repositories) or through `gh` with `gh search repos --owner access-nri --include-forks -- topic:build-ci-enabled`.

## Overview

This repository contains reusable workflows used as common entrypoints into a model component build and test pipeline. See the [Entrypoint Workflows section](#using-the-entrypoint-workflows) for more information.

This repository also contains the resources required to build images that are used by the CI infrastructure in `ACCESS-NRI/build-ci-k8s-infra` (which is private), as well as local builds via `docker compose`. More information on this section can be found in it's own [dedicated README.md](./containers/README.md).

## Usage

### Using The Entrypoint Workflows

Generally, the [`ci.yml`](./.github/workflows/ci.yml) workflow can be used by any model component repository in the ACCESS-NRI organisation, it just requires using the reusable workflow from this repository.

Alternatively, for organisations outside of ACCESS-NRI, the `ci-github-hosted.yml` can be used. But...

> [!IMPORTANT]
> Note that the `ci-github-hosted.yml` is slower than the self-hosted variant due to GitHub not caching large images used to initialize compilers and packages, and the lack of a persistent buildcache.

Basic templates for model component repositories CI are available under [`model-component-ci-templates`](./model-component-ci-templates/) - more complex use cases are possible and encouraged!

> [!NOTE]
> Before a model component repository workflow using `ci.yml` is able to run on the `build-ci` runners, the repository must be included in the allowlist for the `build-ci` runner group. Ask an ACCESS-NRI GitHub Administrator to add the model component repository.

The list of inputs are in the above workflow file and explained in the workflow-specific [`README.md`](./.github/workflows/README.md), but at it's simplest it only requires a path to a jinja-templatable spack manifest relative to the model component repository root (more on that in the [Writing Spack Manifests section](#writing-spack-manifests)). For example:

```yaml
jobs:
  build:
    uses: access-nri/build-ci/.github/workflows/ci.yml@v2  # Note that the workflows will only be picked up by the runner if they are from @vX refs!
    with:
      spack-manifest-path: .github/build-ci/manifests/spack.yaml
```

This workflow has also been created with GitHub-Actions-level parallelism in mind, so feel free to matrix the builds as required:

```yaml
jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        file:
          - .github/build-ci/manifests/access-om2.spack.yaml
          - .github/build-ci/manifests/access-esm1p5.spack.yaml
    uses: access-nri/build-ci/.github/workflows/ci.yml@v2
    with:
      spack-manifest-path: ${{ matrix.file }}
      spack-packages-ref: 2025.06.000
      ssh-into-spack-install: true
```

### Writing Spack Manifests

Spack [manifest files](https://spack.readthedocs.io/en/latest/environments.html) are a way to define versions, dependencies (and dependents) and configuration information for software. In this case - model components, and what models they are part of.

The manifest files have almost no restrictions - but in order to build the component at the git ref given by the workflow input `inputs.ref` (which for pull requests is the HEAD of the source branch), one must use the version `@git.{{ ref }}` for the model component.

The double-bracket syntax is unique and not spack specific - the manifest files are actually [Jinja](https://palletsprojects.com/projects/jinja/) templates, in which `{{ ref }}` is replaced by `inputs.ref` at build-time. Additional template variables can be defined through data files that are ingested via the `inputs.spack-manifest-data-path` entrypoint workflow input. You can add the `.j2` suffix to the spack manifest file name, but it isn't required.

A minimal example of a spack manifest file that builds a full model ([`access-om2`](https://github.com/ACCESS-NRI/ACCESS-OM2)) using the repositories model component ([`mom5`](github.com/ACCESS-NRI/MOM5)) is below:

```yaml
spack:
  specs:
    - access-om2 ^mom5@git.{{ ref }}=access-om2 %intel@2021.10.0 target=x86_64
  view: true
  concretizer:
    unify: false
```

More information on this can be found in the [Entrypoint workflow README.md](./.github/workflows/README.md#jinja-templates-and-data)

## Development

### Developing The Entrypoint Workflows

Similar to `build-cd`, we version the workflows using [SemVer](https://semver.org/) - specifically, we have protected branch references for the major versions (`v2`, `v3`, etc), and tags for minor and patch updates to the entrypoint workflows (`v2.0.0`, `v2.1.0`. `v2.1.2`). Users of the entrypoint workflows are free to use either reference for their invocations, but it's recommended to use major version branch references to pick up bug fixes and features, without breaking changes.

For developers of the workflow, we consider the following:

* Major version updates are when there are changes to existing entrypoint workflow inputs; the addition of new, required inputs; new, required secrets/variables; or significant changes to core workflow functionality.
* Minor version updates are when there are new, optional entrypoint workflow inputs or new features in line with core workflow functionality.
* Patch version updates are when there are bugfixes to the workflow.

> [!IMPORTANT]
> When there is a new major version, a new protected branch will need to be created that the proposed changes will be merged into. Furthermore, one will need to update the default branch to the new major version. Finally, the new major version ref will have to be added to the workflow allowlist in the `build-ci` runner group, so the runners will accept jobs from that version of the workflow.
