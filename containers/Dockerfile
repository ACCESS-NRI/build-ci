# Copyright 2023-2025 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0
#
# Contains build targets: base-os-rocky, base-os-suse, base-spack, ci, dev

################################################################################
# OS = {rocky,suse}
ARG OS=rocky
# e.g. docker build -f Dockerfile.base-spack --build-arg OS=suse -t spack-dev-suse:1 --target dev --no-cache --progress=plain .


################################################################################
# NOTE: Keep an eye on:
#       ${SPACK_ROOT}/share/spack/templates/container/rockylinux_8.dockerfile
FROM rockylinux/rockylinux:8.10 AS base-os-rocky

# csh currently required for some build scripts e.g. MOM5
# yq required for spack manifest modification
RUN dnf update -y \
 && dnf -y install \
    autoconf \
    automake \
    binutils \
    bison \
    bzip2 \
    csh \
    flex \
    curl \
    file \
    findutils \
    gcc \
    gcc-c++ \
    gcc-gfortran \
    git \
    glibc-devel \
    jq \
    libtool \
    gnupg2 \
    hg \
    hostname \
    iproute \
    make \
    patch \
    patchutils \
    perl \
    pkgconf \
    pkgconf-m4 \
    pkgconf-pkg-config \
    python3 \
    python3-pip \
    python3-setuptools \
    svn \
    unzip \
    xz \
    zstd \
 && rm -rf /var/cache/dnf \
 && dnf clean all \
 && curl -L https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64 -o /usr/bin/yq \
 && chmod +x /usr/bin/yq

################################################################################
FROM opensuse/leap:15.5 AS base-os-suse

# csh currently required for some build scripts e.g. MOM5
RUN zypper ref \
&&  zypper update -y \
&&  zypper install -y \
    autoconf \
    automake \
    binutils \
    bison \
    bzip2 \
    flex \
    curl \
    file \
    findutils \
    gcc \
    gcc-c++ \
    gcc-fortran \
    git \
    glibc-devel \
    jq \
    libtool \
    hg \
    hostname \
    iproute \
    make \
    patch \
    patchutils \
    perl \
    pkgconf \
    python3 \
    python3-pip \
    python3-setuptools \
    unzip \
    xz \
    zstd \
    gzip \
    gpg2 \
    subversion \
    tcsh \
    vim \
 &&  zypper clean \
 && curl -L https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64 -o /usr/bin/yq \
 && chmod +x /usr/bin/yq

################################################################################
FROM base-os-$OS AS base-spack

ARG SPACK_GIT_URL=https://github.com/ACCESS-NRI/spack.git
ARG SPACK_VERSION=v0.22
ARG SPACK_REPO_VERSION=releases/${SPACK_VERSION}
ARG SPACK_PACKAGES_REPO_VERSION=main
ARG SPACK_CONFIG_REPO_VERSION=main
ARG SPACK_TARGET=x86_64
ARG SPACK_CONFIG_DIR=/opt/spack-config/${SPACK_VERSION}/ci
ARG SOURCE_COMPILERS_SPACK_MANIFEST=upstream/prod/compilers.spack.yaml
ARG SOURCE_PACKAGES_SPACK_MANIFEST=upstream/prod/packages.spack.yaml

ENV SPACK_ROOT=/opt/spack
ENV GNUPGHOME=${SPACK_ROOT}/opt/spack/gpg
ENV ENV_SPACK_TARGET=${SPACK_TARGET}
ENV ENV_COMPILERS_SPACK_MANIFEST=/opt/compilers.spack.yaml
ENV ENV_PACKAGES_SPACK_MANIFEST=/opt/packages.spack.yaml

# Export the repo versions for comparison in the runner target
ENV SPACK_PACKAGES_REPO_VERSION=${SPACK_PACKAGES_REPO_VERSION}
ENV SPACK_CONFIG_REPO_VERSION=${SPACK_CONFIG_REPO_VERSION}
ENV SPACK_REPO_VERSION=${SPACK_REPO_VERSION}

# Export the spack config directory for the runner target
ENV SPACK_CONFIG_DIR=${SPACK_CONFIG_DIR}

# TODO: Ideally we want spack-enable.bash to be the only source of these
#       definitions. See if spack-enable.bash can be used instead.
# NOTE: In the meantime, keep in-sync with spack-config/spack-enable.bash
ENV SPACK_DISABLE_LOCAL_CONFIG="true"
ENV SPACK_USER_CACHE_PATH=${SPACK_ROOT}/..

LABEL au.org.access-nri.image.spack-repo-version=${SPACK_REPO_VERSION}
LABEL au.org.access-nri.image.spack-packages-repo-version=${SPACK_PACKAGES_REPO_VERSION}
LABEL au.org.access-nri.image.spack-config-repo-version=${SPACK_CONFIG_REPO_VERSION}

SHELL ["/bin/bash", "-c"]

# Install spack
RUN <<EOF
git clone -c feature.manyFiles=true ${SPACK_GIT_URL} ${SPACK_ROOT} --branch ${SPACK_REPO_VERSION}

# Install ACCESS-NRI's spack-packages repo
git clone  https://github.com/ACCESS-NRI/spack-packages.git /opt/spack-packages --branch ${SPACK_PACKAGES_REPO_VERSION}

# Install ACCESS-NRI's spack-config repo
git clone  https://github.com/ACCESS-NRI/spack-config.git /opt/spack-config --branch ${SPACK_CONFIG_REPO_VERSION}

# Exit with ENOENT 2 "No such file or directory", if the directory does not
# exist
if [ -d "${SPACK_CONFIG_DIR}" ]; then ln -s -r -v ${SPACK_CONFIG_DIR}/* ${SPACK_ROOT}/etc/spack/; else echo "${SPACK_CONFIG_DIR} does not exist!"; exit 2; fi
EOF

# Enables setting Spack setup type via SHELL command
# docker-shell:      Use for build RUN steps
# interactive-shell: Use for interactive shell instances
# spack-env:         Use for CMD invocations (e.g. CI runners)
# ${SPACK_ROOT}/share/spack/templates/container/bootstrap-base.dockerfile:
RUN ln -s ${SPACK_ROOT}/share/spack/docker/entrypoint.bash \
    /usr/local/bin/docker-shell && \
    ln -s ${SPACK_ROOT}/share/spack/docker/entrypoint.bash \
    /usr/local/bin/interactive-shell && \
    ln -s ${SPACK_ROOT}/share/spack/docker/entrypoint.bash \
    /usr/local/bin/spack-env

COPY ${SOURCE_COMPILERS_SPACK_MANIFEST} ${ENV_COMPILERS_SPACK_MANIFEST}
COPY ${SOURCE_PACKAGES_SPACK_MANIFEST} ${ENV_PACKAGES_SPACK_MANIFEST}

# Setup Spack environment for subsequent RUN steps
SHELL ["docker-shell"]

# https://spack.readthedocs.io/en/latest/bootstrapping.html
# Spack is configured to bootstrap its dependencies lazily by default;
# i.e. the first time they are needed and can’t be found.

################################################################################
# Install compilers and other common packages
FROM base-spack AS upstream

LABEL org.opencontainers.image.source=https://github.com/ACCESS-NRI/build-ci

# Install compilers and low-level, common packages
RUN <<EOF
echo "Installing compilers"
spack env activate compilers --create --envfile ${ENV_COMPILERS_SPACK_MANIFEST}
spack spec
spack install --fail-fast || exit
spack env deactivate
yq '.spack.specs[]' "${ENV_COMPILERS_SPACK_MANIFEST}" | while read compiler; do
  echo "Loading compiler: $compiler"
  spack load $compiler
  spack compiler find
done

echo "Installing common packages"
spack env activate packages --create --envfile ${ENV_PACKAGES_SPACK_MANIFEST}
spack install --fail-fast || exit
spack env deactivate

spack clean --downloads
EOF

################################################################################
FROM base-spack AS runner

LABEL org.opencontainers.image.source=https://github.com/ACCESS-NRI/build-ci

# Install tmate on the runner for remote access during workflows via mxschmitt/action-tmate
RUN <<EOF
curl -L https://github.com/tmate-io/tmate/releases/download/2.4.0/tmate-2.4.0-static-linux-amd64.tar.xz -o static-tmate.tar.xz
tar -xvf static-tmate.tar.xz --strip-components=1
mv tmate /usr/local/bin/tmate
rm -rf static-tmate.tar.xz
EOF

# Set up ACCESS Spack buildcache
RUN spack mirror add --autopush --unsigned runner_set_buildcache /opt/runner_set_buildcache

# We copy, but don't source this file here, because it relies on the upstream volume being set up
COPY spack-config/ci-spack-enable.bash ${SPACK_ROOT}/../spack-config/ci-spack-enable.bash

spack clean --downloads
EOF

ENTRYPOINT ["/bin/bash", "/opt/spack/share/spack/docker/entrypoint.bash"]
CMD ["interactive-shell"]
