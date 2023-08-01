for package in "$1"; do
    spack env create $package $package.spack.yaml
    spack env activate $package
    spack -d install --only dependencies --fail-fast
    spack gc -y
    spack env deactivate
done