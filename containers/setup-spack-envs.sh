for package in "$1"; do
    spack env create $package
    spack env activate $package
    spack -d install --add ${COMPILER_PACKAGE}@${COMPILER_VERSION}
    spack load ${COMPILER_PACKAGE}@${COMPILER_VERSION}
    spack compiler find --scope site
    spack -d install --only dependencies ${PACKAGE}%${COMPILER_NAME}@${COMPILER_VERSION}
done