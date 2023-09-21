# build-ci Developer Documentation

This documentation is intended to give a rationale for design decisions, and a more in-depth look into the build-ci pipelines.

This repository contains three main pipelines:

* Dependency Image Pipeline: uses `build-and-push-image-build.yml`, `dependency-image-pipeline.yml`, `dependency-image-build.yml` and `build-and-push-image.yml` workflows.
* Model Test Pipeline: uses `build-package.yml` workflow.
* JSON Lint Pipeline: uses `json-lint.yml` workflow.

How they are used can be found in the [CI Run Through section](#ci-workflow-run-through).

## Inputs and Outputs

### I/O for Dependency Image Build Pipeline

#### Dependency Image Build Pipeline Inputs

This pipeline has explicit inputs:

* `spack-packages-version`: A tag or branch of the `access-nri/spack_packages` repository. This allows provenance of the build process of models.
* `model`: a coupled model name (such as `access-om2` or `access-om3`) or `all` if we want to build dependency images for all coupled models defined in `containers/models.json`.

It also indirectly uses:

* `containers/compilers.json`: This is a structure of all the compilers we want to test against.
* `containers/models.json`: This is a structure of all the coupled models (and their associated model components) that we want to test against.
* `containers/Dockerfile.*`: uses these Dockerfiles to create the `base-spack` and `dependency` images.

#### Dependency Image Build Pipeline Outputs

* `base-spack` Docker image: Of the form `base-spack-<compiler name><compiler version>-<spack_packages version>:latest`. A docker image that contains a `spack` install, `access-nri/spack_packages` repo at the specified version, and a site-wide compiler for spack to use to build dependencies.
* `dependency` Docker image: Of the form `build-<coupled model>-<compiler name><compiler version>-<spack_packages version>:latest`: A docker image based on the above `base-spack` image, that contains all the model components dependencies (separated by `spack env`s), but not the models themselves. The models are added on top of the install in a different pipeline, negating the need for a costly install of the dependencies again (in most cases).

### I/O for Model Test Pipeline

#### Model Test Pipeline Inputs

There are no explicit inputs to this workflow. The information required is inferred by the model repository that calls the `build-package.yml` workflow.

However, there are indirect inputs into this pipeline:

* Appropriate `dependency` Docker images of the form: `ghcr.io/access-nri/build-<coupled model>-<compiler name><compiler version>-<spack_packages version>:latest`.
* `containers/compilers.json`: This is a structure of all the compilers we want to test against.
* `containers/models.json`: This is a structure of all the coupled models (and their associated model components) that we want to test against.

#### Model Test Pipeline Outputs

* `<env>.original.spack.lock`: A `spack.lock` file from the `spack env` associated with the modified model repository (eg. `mom5`), before the installation of the modified model. If the install succeeds then then this `spack.lock` file was unmodified during the installation and can be used to recreate this `spack env`. This file is uploaded as an artifact.
* Optionally, a `<env>.force.spack.lock`: If the installation fails (namely, if installing the modified model would change the `spack.lock` file) we force a regeneration of the `spack.lock` file and upload this as an artifact as well.

### I/O for JSON Linter Pipeline

#### Inputs for JSON Linter Pipeline

This pipeline has no explicit inputs.

However, there are indirect inputs into this pipeline:

* `*.json`: All JSON files that need to be validated.
* `*.schema.json`: All JSON schemas that validate the above `*.json` files.

#### Outputs for JSON Linter Pipeline

There are no outputs from this pipeline (outside of checks).

## CI Workflow Run Through

### Dependency Image Build Pipeline

The rationale for this pipeline is the creation of a model-dependency docker image. This image contains spack, the `spack env`ironments, and the dependencies for the install of a model, but not the model itself. This allows modified models/model components to be 'dropped in' to the dependency image and installed quickly, without needing to install the dependencies again.

As an overview, this workflow, given a `access-nri/spack_packages` repo version and coupled model(s):

* Generates a staggered `compiler x model` matrix based on the `compilers.json` and `models.json`. This allows generation and testing of multiple different compiler and model image combinations in parallel.  
* Uses an existing `base-spack` docker image (or creates it if it doesn't exist) that contains an install of spack, access-nri/spack_packages and a given compiler.
* Using the above `base-spack` image, creates a spack-based model-dependency docker image that separates each model (and it's components) into `spack env`s. This has all the dependencies of the model installed, but not the model itself.

#### Pipeline Overview

In the following example, we have two compilers (`c1, c2`) and two (coupled) models (`m1, m2`).

##### The Beginning (build-and-push-image-build.yml)

This pipeline begins at `build-and-push-image-build.yml`:

```txt
build-and-push-image-build.yml [compilers c1 c2]
```

This workflow is responsible for generating the matrix of compilers (from `containers/compilers.json`) and the information necessary for creating a matrix of coupled models for a future matrix (from `models.json`).

Rather than doing the `compiler x model` matrix at the beginning of the workflow, we do the model matrix later. This is because we would be duplicating the creation of the `base-spack` image, which thrashes dockers caching. A more detailed explanation is in [the appendix of this document](#on-the-matrix-strategy-for-the-dependency-image-pipeline).

After the `compiler` matrix is created, we call the `dependency-image-pipeline.yml` workflow on each of the compilers, parallelizing the pipeline like so:

```txt
build-and-push-image-build.yml [compilers c1 c2]
    |- [c1] dependency-image-pipeline.yml
    |- [c2] dependency-image-pipeline.yml 
```

##### Creation of `base-spack` and setup of dependency image (dependency-image-pipeline.yml)

In this workflow, given the specs for a given compiler, a `spack_packages` version, and a list of models for a future `model` matrix strategy, we seek to:

* Check that a suitable `base-spack` image doesn't already exists. This would be one that has the same compiler and same version of spack_packages.
* If it doesn't exist, create and push it using the reusable `build-and-push-image.yml` workflow.
* After those steps, create the aforementioned `model` matrix strategy, running the `dependency-image-build.yml` workflow for each of the models. At this point, the pipeline looks like this:

```txt
build-and-push-image-build.yml [compilers c1 c2]
    |- [c1] dependency-image-pipeline.yml
    |   |- build-and-push-image.yml (base-spack-c1)
    |   |- dependency-image-build.yml [models m1 m2]
    |- [c2] dependency-image-pipeline.yml
        |- build-and-push-image.yml (base-spack-c2)
        |- dependency-image-build.yml [models m1 m2]
```

##### Creation of Dependency Image (dependency-image-build.yml)

Finally, with the `base-spack` image created, and the models that need to be built turned into a matrix strategy, we can create the dependency image. At this stage, we have as inputs: a given compiler spec, a `spack_packages` version, and the name of a single coupled model that we want turned into a dependency image. We have all the information necessary for this now.  

In the `dependency-image-build.yml` workflow, we:

* Get the associated model components of our coupled model from the `containers/models.json` file.
* Build and push the dependency image given the existing `base-spack` image as a base, and the list of model components from the previous job, using the reusable `build-and-push-image.yml` workflow.

This leads to a final pipeline looking like the following:

```txt
build-and-push-image-build.yml [compilers c1 c2]
    |- [c1] dependency-image-pipeline.yml
    |   |- build-and-push-image.yml (base-spack-c1)
    |   |- dependency-image-build.yml [models m1 m2]
    |       |- [m1] build-and-push-image.yml (dep-image-c1-m1) 
    |       |- [m2] build-and-push-image.yml (dep-image-c1-m2) 
    |- [c2] dependency-image-pipeline.yml 
    |   |- build-and-push-image.yml (base-spack-c2)
    |   |- dependency-image-build.yml [models m1 m2]
    |       |- [m1] build-and-push-image.yml (dep-image-c2-m1) 
    |       |- [m2] build-and-push-image.yml (dep-image-c2-m2) 
```

### Model Test Pipeline

This workflow seeks to build upon the Dependency Image Pipeline as explained above by taking an appropriate dependency image and attempting to install a modified (most likely from a PR) model over the top. This allows further testing and runs of a modified model without the excessive overhead of installing dependencies from scratch.

#### Model Test Pipeline Overview

Model repositories that implement the `model-build-test-ci.yml` starter workflow (such as the [access-nri/MOM5](https://github.com/ACCESS-NRI/MOM5/blob/master/.github/workflows/model-build-test-ci.yml) repo) will call `build-ci`s `build-package.yml` workflow.

This workflow begins by inferring the 'appropriate dependency image' based on a number of factors, mostly coming from the name of the dependency image (which is of the form `build-<coupled model>-<compiler name><compiler version>-<spack_packages version>:latest`).

In order to find:

* `spack_packages version`: In the `setup-spack-packages` job, we take the latest tagged version of the `access-nri/spack_packages` repo.
* `coupled model`: In the `setup-model` and `setup-build-ci` jobs, we use the name of the calling repository (eg. `cice5`) and `build-ci`s `containers/models.json` to infer the overarching `coupled model` name.
* `compiler name`/`compiler version`: In the `setup-build-ci` job, we use all compilers from the `containers/compilers.json` file. This would mean that another matrix strategy would be in order.

Given those inferences, we would be able to find the appropriate dependency images to install the modified models into.

We then use those containers to upload the original `spack.lock` files (also known as lockfiles) and then attempt to install the modified model in the appropriate `spack env`. If this fails, we force a recreation of the lockfile and upload this one as well, for reference.

### JSON Linter Pipeline

This is a relatively simple pipeline (found in `json-lint.yml`) that looks for `*.schema.json` files in `containers`, matches them up with the associated `*.json` files and makes sure they comply with the given schema.

## Reusable Workflows

### build-and-push-image.yml

`build-and-push-image.yml` is the most used reusable workflow. This workflow builds, caches, and pushes a given Dockerfile to a given container registry. Build args and build secrets can also be added.

## Appendix

### On the matrix strategy for the Dependency Image Pipeline

At first glance, the Dependency Image Pipeline seems needlessly complex. Why do we do a `compiler` matrix then a `model` matrix strategy, instead of a `compiler x model` matrix strategy? This section attempts to explain it.

At it's core, it is about removing duplication of effort and effectively using the cache, rather than thrashing the cache.

Imagine we have a `compiler x model` matrix with 2 compilers `c1, c2` and two models `m1, m2`. The matrix strategy would be:

```txt
[compiler x model] --- [c1, m1] --- base-spack-c1 image --- dep-c1-m1 image
                    |- [c1, m2] --- base-spack-c1 image --- dep-c1-m2 image
                    |- [c2, m1] --- base-spack-c2 image --- dep-c2-m1 image
                    |- [c2, m2] --- base-spack-c2 image --- dep-c2-m2 image
```

The two copies of `base-spack-c1` and `base-spack-c2` images are created in parallel, which duplicates effort and makes the cache unusable. Instead, if we stagger the creation of the matrix, as noted below:  

```txt
[compiler] --- [c1] --- base-spack-c1 image --- [model] --- [m1] --- dep-c1-m1 image
            |                                            |- [m2] --- dep-c1-m2 image
            |- [c2] --- base-spack-c2 image --- [model] --- [m1] --- dep-c2-m1 image
                                                         |- [m2] --- dep-c1-m2 image
```

We instead only create one copy of `base-spack-c1` and `base-spack-c2`, leveraging the various caches we use.
