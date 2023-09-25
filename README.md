# build-ci

A central repository for reusable CI compilation testing workflows and containers used across ACCESS-NRI supported projects.

This repository is also responsible for building Docker images used for CI compilation testing.

## Overview

This repository contains three overarching CI pipelines:

### Dependency Image Pipeline

This pipeline creates Docker images that contain an install of `spack`, a version of the `access-nri/spack_packages` [repository](https://github.com/ACCESS-NRI/spack_packages), and a set of independent `spack env`ironments that contain all the dependencies for all the model components of a coupled model.

This allows the install of modified models (and model components) for quick CI testing, rather than having to install an entire dependency tree every time a PR is opened.

These packages are in the [`build-ci` repo](https://github.com/orgs/ACCESS-NRI/packages?tab=packages&q=build-).

### Model Test Pipeline

This pipeline is called by any model repo that uses the `model-build-test-ci.yml` starter workflow. It uses the images mentioned above to test the installability of modified models (usually created via PRs) quickly.

Examples of this are [access-nri/cice5](https://github.com/ACCESS-NRI/cice5/blob/master/.github/workflows/model-build-test-ci.yml) and [access-nri/mom5](https://github.com/ACCESS-NRI/MOM5/blob/master/.github/workflows/model-build-test-ci.yml)

### JSON Lint Pipeline

This pipeline checks that a given `*.json` file complies with an associated `*.schema.json` file. Right now it is only being used in the `build-ci` repo.

## Usage

### For Model repositories

If you want to use the Model Test Pipeline (and the model is available in `access-nri/spack_packages` and has an associated entry in `containers/models.json`), go to the repo, then the `Actions` tab, then the `New Workflow` button. You should see a section of starter workflows by ACCESS-NRI. Simply add the `Model Build Test Workflow`, and next time there is a PR on that repo, it will test for installability.

### Creation of your own Dependency Images

There is an associated `workflow_dispatch` trigger on `build-and-push-image-build.yml` that allows the creation of your own `base-spack` and `dependency` images. Just make sure that the `spack_packages version` tag exists in the `access-nri/spack_packages` repo.

A [Web UI trigger](https://github.com/ACCESS-NRI/build-ci/actions/workflows/build-and-push-image-build.yml) is available.

## More information

For more of a dev-focussed look at the CI pipeline, see `README-DEV.md`.
