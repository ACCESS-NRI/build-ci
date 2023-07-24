# Utils
In this directory are scripts and data files used by the various GitHub Actions workflows. 

## (test_)matrix_generation.py
Used by `.github/workflows/notified-of-spack-packages-update.yml` workflow for generating the list of packages that need to be updated and turned into images. Uses `util/supported-dependency-mapping.txt`. 

There is also an associated pytest file for making sure the matrix generation works as expected!

## supported/full-dependency-mapping.txt
The `full-dependency-mapping` includes mappings for packages that are not (yet) supported by our build-ci process. 

The `supported-dependency-mapping` includes mappings for packages that we do currently support. 

These files are (for now!) manually generated by using `spack dependents` and `spack find --deps <package>` on a model-filled ACCESS-NRI spack installation.  

The structure is a as follows: the first element in the line is the package concerned, and the rest are the things that depend on it, and hence are the things that will need to be rebuilt if the package is updated. 