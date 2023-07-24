FROM spack/rockylinux8:v0.20.1

ARG SPACK_PACKAGES_REPO_VERSION
ARG PACKAGE
ARG COMPILER_NAME
ARG COMPILER_PACKAGE
ARG COMPILER_VERSION

ENV SPACK_PACKAGES_REPO_ROOT=/opt/spack_packages

WORKDIR $SPACK_ROOT

RUN git clone --depth 1 --branch ${SPACK_PACKAGES_REPO_VERSION} https://github.com/ACCESS-NRI/spack_packages.git ${SPACK_PACKAGES_REPO_ROOT}

COPY repos.yaml $SPACK_ROOT/etc/spack/repos.yaml

RUN spack -d install ${COMPILER_PACKAGE}@${COMPILER_VERSION} && \
    spack load ${COMPILER_PACKAGE}@${COMPILER_VERSION} && \
    spack compiler find --scope site

RUN spack -d install --only dependencies ${PACKAGE}%${COMPILER_NAME}@${COMPILER_VERSION}