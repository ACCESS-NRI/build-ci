FROM spack/rockylinux8:v0.20.1

ARG SPACK_PACKAGES_REPO_VERSION="2023.07.25"
ARG PACKAGES="mom5 cice5"
ARG COMPILER_NAME="intel"
ARG COMPILER_PACKAGE="intel-oneapi-compilers"
ARG COMPILER_VERSION="2021.1.2"

ENV SPACK_PACKAGES_REPO_ROOT=/opt/spack_packages

WORKDIR $SPACK_ROOT

RUN git clone --depth 1 --branch ${SPACK_PACKAGES_REPO_VERSION} https://github.com/ACCESS-NRI/spack_packages.git ${SPACK_PACKAGES_REPO_ROOT}

COPY repos.yaml $SPACK_ROOT/etc/spack/repos.yaml

RUN spack gpg init

# Add buildcache mirror
RUN --mount=type=secret,id=S3_ACCESS_KEY_ID \
    --mount=type=secret,id=S3_ACCESS_KEY_SECRET \
    spack mirror add \
    --s3-access-key-id `cat /run/secrets/S3_ACCESS_KEY_ID` \
    --s3-access-key-secret `cat /run/secrets/S3_ACCESS_KEY_SECRET` \
    s3_buildcache \
    s3://access-nri-spack-cache

# Import buildcache keys
RUN --mount=type=secret,id=access-nri.priv \
    spack gpg trust /run/secrets/access-nri.priv
RUN --mount=type=secret,id=access-nri.pub \
    spack gpg trust /run/secrets/access-nri.pub

# Iteratively create an environment for each package in the list
COPY setup-spack-envs.sh .
RUN ./setup-spack-envs ${PACKAGES} ${COMPILER_NAME} ${COMPILER_PACKAGE} ${COMPILER_VERSION}

ENTRYPOINT [ "spacktivate" ]