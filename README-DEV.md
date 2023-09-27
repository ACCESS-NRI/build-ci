# build-ci Developer Documentation

This documentation is intended to give a rationale for design decisions, and a more in-depth look into the build-ci pipelines.

This repository contains three main pipelines:

* Dependency Image Pipeline: uses `dep-image-1-start.yml`, `dep-image-2-build-base.yml`, `dep-image-3-build.yml` and `build-docker-image.yml` workflows.
* Model Test Pipeline: uses `model-1-build.yml` workflow.
* JSON Validate Pipeline: uses `json-1-validate.yml` workflow.

How they are used can be found in the [CI Run Through section](#ci-workflow-run-through).

## Inputs and Outputs

### Dependency Image Build Pipeline

#### Inputs

This pipeline has explicit inputs, defined in the [`on.workflow_call.inputs` section](https://github.com/ACCESS-NRI/build-ci/blob/1b998192946c364fb75040e6807e7143c9123527/.github/workflows/dep-image-1-start.yml#L5-L15):

* `spack-packages-version`: A tag or branch of the `access-nri/spack_packages` [repository](https://github.com/ACCESS-NRI/spack_packages). This allows provenance of the build process of models.
* `model`: a coupled model name (such as `access-om2` or `access-om3`) or `all` if we want to build dependency images for all coupled models defined in `containers/models.json`.

It also indirectly uses:

* [`containers/compilers.json`](https://github.com/ACCESS-NRI/build-ci/blob/main/containers/compilers.json): This is a data structure containing all the compilers we want to test against.
* [`containers/models.json`](https://github.com/ACCESS-NRI/build-ci/blob/main/containers/models.json): This is a data structure containing all the coupled models (and their associated model components) that we want to test against.
* [`containers/Dockefile.base-spack`](https://github.com/ACCESS-NRI/build-ci/blob/main/containers/Dockerfile.base-spack), [`containers/Dockerfile.dependency`](https://github.com/ACCESS-NRI/build-ci/blob/main/containers/Dockerfile.dependency) : uses these Dockerfiles to create the `base-spack` and `dependency` images.

#### Outputs

This pipeline creates two docker image outputs:

* `base-spack` Docker image: Of the form `base-spack-<compiler name><compiler version>-<spack_packages version>:latest`. A docker image that contains a `spack` install, `access-nri/spack_packages` repo at the specified version, and a site-wide compiler for spack to use to build dependencies. An example of this package is [`base-spack-intel2021.2.0-main`](https://github.com/ACCESS-NRI/build-ci/pkgs/container/base-spack-intel2021.2.0-main).
* `dependency` Docker image: Of the form `build-<coupled model>-<compiler name><compiler version>-<spack_packages version>:latest`: A docker image based on the above `base-spack` image, that contains all the model components dependencies (separated by `spack env`s), but not the models themselves. The models are added on top of the install in a different pipeline, negating the need for a costly install of the dependencies again (in most cases). An example of this package is [`build-access-om3-intel2021.2.0-main`](https://github.com/orgs/ACCESS-NRI/packages/container/package/build-access-om3-intel2021.2.0-main).

### Model Test Pipeline

#### Inputs

There are no explicit inputs to this workflow. The information required is inferred by the model repository that calls the [`model-1-build.yml`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/model-1-build.yml) workflow.

However, there are indirect inputs into this pipeline:

* Appropriate `dependency` Docker images of the form: `ghcr.io/access-nri/build-<coupled model>-<compiler name><compiler version>-<spack_packages version>:latest`.
* [`containers/compilers.json`](https://github.com/ACCESS-NRI/build-ci/blob/main/containers/compilers.json): This is a data structure containing all the compilers we want to test against.
* [`containers/models.json`](https://github.com/ACCESS-NRI/build-ci/blob/main/containers/models.json): This is a data structure containing all the coupled models (and their associated model components) that we want to test against.

#### Outputs

* `<env>.original.spack.lock`: A `spack.lock` file from the `spack env` associated with the modified model repository (eg. `mom5`), before the installation of the modified model. If the install succeeds then this `spack.lock` file was unmodified during the installation and can be used to recreate this `spack env`. This file is uploaded as an artifact.
* Optionally, a `<env>.force.spack.lock`: If the installation fails (namely, if installing the modified model would change the `spack.lock` file) we force a regeneration of the `spack.lock` file and upload this as an artifact as well.

### JSON Validator Pipeline

This workflow finds all the [JSON Schema](https://json-schema.org/) files in the project, i.e. those with the '.schema.json' extension, and then runs [`jsonschema`](https://pypi.org/project/jsonschema/) on the matching json files. e.g. `containers/model.json` is validated against `containers/models.schema.json`.

#### Inputs

This pipeline has no explicit inputs.

However, there are indirect inputs into this pipeline:

* `*.json`: All JSON files that need to be validated.
* `*.schema.json`: All JSON schemas that validate the above `*.json` files.

#### Outputs

There are no specific outputs from this pipeline. Only the normal output to the terminal and status checks reported by GitHub workflows.

## CI Workflow Run Through

### Dependency Image Build Pipeline

The rationale for this pipeline is the creation of a model-dependency docker image. This image contains spack, the `spack env`s, and the dependencies for the install of a model, but not the model itself. This allows modified models/model components to be 'dropped in' to the dependency image and installed quickly, without needing to install the dependencies again.

As an overview, this workflow, given a `access-nri/spack_packages` repo version and coupled model(s):

* Generates a staggered `compiler x model` matrix based on the [`compilers.json`](https://github.com/ACCESS-NRI/build-ci/blob/maine/containers/compilers.json) and [`models.json`](https://github.com/ACCESS-NRI/build-ci/blob/main/containers/models.json). This allows generation and testing of multiple different compiler and model image combinations in parallel.  
* Uses an existing `base-spack` docker image (or creates it if it doesn't exist) that contains an install of spack, access-nri/spack_packages and a given compiler.
* Using the above `base-spack` image, creates a spack-based model-dependency docker image that separates each model (and it's components) into `spack env`s. This has all the dependencies of the model installed, but not the model itself.

#### Pipeline Overview

There will be diagrams that seek to explain the calling and matrix structure of the pipeline, in parts. They will look like this:

```txt
workflow.yml [component comp1 comp2 comp3]
  |- [comp1] another-workflow.yml
  |- [comp2] another-workflow.yml
  |- [comp3] another-workflow.yml
```

In the above diagram, the first line means that we initially call `workflow.yml`. Within that workflow, we have a matrix strategy in which we call `another-workflow.yml` with each part of the `component` matrix in parallel (with these components being `comp1`, `comp2` and `comp3`).

In the example we will be using for this pipeline, we have a compiler matrix with two compilers (`c1, c2`) and a model matrix with two (coupled) models (`m1, m2`). 

##### The Beginning (dep-image-1-start.yml)

This pipeline begins at [`dep-image-1-start.yml`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/dep-image-1-start.yml):

```txt
dep-image-1-start.yml [compilers c1 c2]
```

This workflow is responsible for generating the matrix of compilers (from `containers/compilers.json`) and the information necessary for creating a matrix of coupled models for a future matrix (from `models.json`).

Rather than doing the `compiler x model` matrix at the beginning of the workflow, we do the model matrix later in a staggered approach. We do this because it removes duplication of effort and effectively uses the cache, rather than thrashing it. The differences between a `compiler x model` and a staggered `compiler` then `matrix` model strategy are explained below.

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

After the `compiler` matrix is created, we call the `dep-image-2-build-base.yml` workflow on each of the compilers, parallelizing the pipeline like so:

```txt
dep-image-1-start.yml [compilers c1 c2]
    |- [c1] dep-image-2-build-base.yml
    |- [c2] dep-image-2-build-base.yml 
```

##### Creation of `base-spack` and setup of dependency image (dep-image-2-build-base.yml)

In this workflow, given the specs for a given compiler, a `spack_packages` version, and a list of models for a future `model` matrix strategy, we seek to:

* Check that a suitable `base-spack` image doesn't already exists. This would be one that has the same compiler and same version of `spack_packages`.
* If it doesn't exist, create and push it using the reusable [`build-docker-image.yml`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/build-docker-image.yml) workflow.
* After those steps, create the aforementioned `model` matrix strategy, running the [`dep-image-3-build.yml`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/dep-image-3-build.yml) workflow for each of the models. At this point, the pipeline looks like this:

```txt
dep-image-1-start.yml [compilers c1 c2]
    |- [c1] dep-image-2-build-base.yml
    |   |- build-docker-image.yml (base-spack-c1)
    |   |- dep-image-3-build.yml [models m1 m2]
    |- [c2] dep-image-2-build-base.yml
        |- build-docker-image.yml (base-spack-c2)
        |- dep-image-3-build.yml [models m1 m2]
```

##### Creation of Dependency Image (dep-image-3-build.yml)

Finally, with the `base-spack` image created, and the models that need to be built turned into a matrix strategy, we can create the dependency image. At this stage, we have as inputs: a given compiler spec, a `spack_packages` version, and the name of a coupled model, e.g. `access-om2`, that we want turned into a dependency image. We have all the information necessary for this now.  

In the `dep-image-3-build.yml` workflow, we:

* Get the associated model components of our coupled model from the [`containers/models.json`](https://github.com/ACCESS-NRI/build-ci/blob/main/containers/models.json) file.
* Build and push the dependency image given the existing `base-spack` image as a base, and the list of model components from the previous job, using the reusable [`build-docker-image.yml`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/build-docker-image.yml) workflow.

This leads to a final pipeline looking like the following:

```txt
dep-image-1-start.yml [compilers c1 c2]
    |- [c1] dep-image-2-build-base.yml
    |   |- build-docker-image.yml (base-spack-c1)
    |   |- dep-image-3-build.yml [models m1 m2]
    |       |- [m1] build-docker-image.yml (dep-image-c1-m1) 
    |       |- [m2] build-docker-image.yml (dep-image-c1-m2) 
    |- [c2] dep-image-2-build-base.yml 
    |   |- build-docker-image.yml (base-spack-c2)
    |   |- dep-image-3-build.yml [models m1 m2]
    |       |- [m1] build-docker-image.yml (dep-image-c2-m1) 
    |       |- [m2] build-docker-image.yml (dep-image-c2-m2) 
```

### Model Test Pipeline

This workflow seeks to build upon the Dependency Image Pipeline as explained above by taking an appropriate dependency image and attempting to install a modified (most likely from a PR) model over the top. This allows further testing and runs of a modified model without the excessive overhead of installing dependencies from scratch.

#### Overview

Model repositories that implement the [`model-build-test-ci.yml`](https://github.com/ACCESS-NRI/.github/blob/main/workflow-templates/model-build-test-ci.yml) starter workflow (such as the [access-nri/MOM5](https://github.com/ACCESS-NRI/MOM5/blob/master/.github/workflows/model-build-test-ci.yml) repo) will call `build-ci`s [`model-1-build.yml`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/model-1-build.yml) workflow.

This workflow begins by inferring the 'appropriate dependency image' based on a number of factors, mostly coming from the name of the dependency image (which is of the form `build-<coupled model>-<compiler name><compiler version>-<spack_packages version>:latest`).

In order to find:

* `spack_packages version`: In the [`setup-spack-packages`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/model-1-build.yml#L8-L26) job, we take the latest tagged version of the `access-nri/spack_packages` repo.
* `coupled model`: In the [`setup-model`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/model-1-build.yml#L28-L37) and [`setup-build-ci`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/model-1-build.yml#L39-L63) jobs, we use the name of the calling repository (eg. `cice5`) and `build-ci`s [`containers/models.json`](https://github.com/ACCESS-NRI/build-ci/blob/main/containers/models.json) to infer the overarching `coupled model` name.
* `compiler name`/`compiler version`: In the [`setup-build-ci`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/model-1-build.yml#L39-L63) job, we use all compilers from the [`containers/compilers.json`](https://github.com/ACCESS-NRI/build-ci/blob/main/containers/compilers.json) file. This would mean that another matrix strategy would be in order.

Given those inferences, we are able to find the appropriate dependency images to use to build the modified models .

We then use those containers to upload the original `spack.lock` files (also known as lockfiles) and then attempt to install the modified model in the appropriate `spack env`. If this fails, we force a recreation of the lockfile and upload this one as well, for reference.

### JSON Validator Pipeline

This is a relatively simple pipeline (found in [`json-1-validate.yml`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/json-1-validate.yml)) that looks for `*.schema.json` files in a `containers` directory and matches them up with their associated `*.json` files and tests that they comply with the given schema.

## Reusable Workflows

### build-docker-image.yml

[`build-docker-image.yml`](https://github.com/ACCESS-NRI/build-ci/blob/main/.github/workflows/build-docker-image.yml) is the most used reusable workflow. This workflow builds, caches, and pushes a given Dockerfile to a given container registry. Build args and build secrets can also be added.
