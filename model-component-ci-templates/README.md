# Example Templates for Repository Build CI

## Overview

For simple repository build CI, including Model Component Repositories (MCRs) and any other repositories that are referenced in spack packages, it can often be enough to just run the defaults for the reusable workflow.

More complex CI is definitely possible, and the basic examples here shouldn't limit more complex use cases - this is just for quick additions to MCRs.

## Examples

> [!NOTE]
> Note that the name of the package that needs to be tested (`{{ package }}`), must be updated in the datafile at `.github/build-ci/data/standard.json`.

Despite not being in these examples, Post-CI jobs can be created that make use of [a slew of outputs](./../.github/workflows/README.md#outputs) from the workflow.

### Basic CI

The simplest use case - a single manifest with no customisation, single compiler already in the upstream, and the default branch for `spack-config` and `spack-packages`. We get the definitions from the `.github/build-ci/data/standard.json` Jinja data file. You are free to change the compiler in the data file, or use other compilers directly in the manifest as your tests require, but in general it's good to keep to the compiler defined in `standard.json`.

Further constraints can be added in the `spack.packages.PACKAGE.require` section, or on the spec itself.

#### Basic CI Instructions

For this case, you will use the `basic-ci.yml` and everything under `build-ci`.

1. Copy `workflows/basic-ci.yml` and put it under the repository's `.github/workflows/basic-ci.yml`.
2. Copy `build-ci/data/standard.json` and put it under `.github/build-ci/data/standard.json`, then replace `YOUR_PACKAGE_HERE` in that file with the repositories spack package under test.
3. Copy `build-ci/manifests` and put it under `.github/build-ci/manifests`
4. Open a PR with those changes, and the CI will run!

### Matrix CI

A common but simple use case - multiple manifests under `.github/build-ci/manifests` that need to be tested in parallel - for example, multiple compilers, different variants, etc.

There is no template for these manifests, as they will be down to the MCR maintainers discretion.

#### Matrix CI Instructions

For this case, you will use the `matrix-ci.yml` and everything under `build-ci`.

1. Copy `workflows/matrix-ci.yml` and put it under the repository's `.github/workflows/matrix-ci.yml`.
2. Copy `build-ci/data/standard.json` and put it under `.github/build-ci/data/standard.json`, then replace `YOUR_PACKAGE_HERE` in that file with the repositories spack package under test.
3. Copy `build-ci/manifests` and put it under `.github/build-ci/manifests`. Note that adding additional manifests is the repository's maintainers responsibility.
4. Open a PR with those changes, and the CI will run!

> [!NOTE]
> For Post-CI jobs for matrices, you will need to use the `job-output-artifact-pattern` to download all artifacts as part of that run, and then `jq` through the list of files to aggregate the data for your own purposes. This is due to GitHub overwriting the value of the matrix job output with the most recent completed instance of the matrix job, rather than all jobs.
