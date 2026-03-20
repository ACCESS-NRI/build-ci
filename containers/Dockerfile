# Copyright 2023-2026 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0
#
# Contains build targets: base-os-rocky, base-os-suse, base-spack, base-ci, upstream, runner

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
    vim \
    which \
    xz \
    zstd \
 # Install gh
 && dnf -y install 'dnf-command(config-manager)' \
 && dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo \
 && dnf -y install gh --repo gh-cli \
 # dnf cleanup
 && rm -rf /var/cache/dnf \
 && dnf clean all

################################################################################
FROM opensuse/leap:15.6 AS base-os-suse

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
 # Install gh
 && zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo \
 && zypper --gpg-auto-import-keys refresh \
 && zypper -n install gh \
 # zypper cleanup
 &&  zypper clean

################################################################################
FROM base-os-$OS AS base-spack

ARG SPACK_GIT_URL=https://github.com/ACCESS-NRI/spack.git
# Default spack version - must be changed across ci*.yml as well
ARG SPACK_VERSION=v1.1
ARG SPACK_REPO_VERSION=releases/${SPACK_VERSION}
ARG SPACK_CONFIG_REPO_VERSION=main
ARG SPACK_TARGET=x86_64
ARG SPACK_CONFIG_DIR=/opt/spack-config/${SPACK_VERSION}/ci
ARG SOURCE_COMPILERS_SPACK_MANIFEST=upstream/compilers.spack.yaml
ARG SOURCE_PACKAGES_SPACK_MANIFEST=upstream/packages.spack.yaml

ENV SPACK_VERSION=${SPACK_VERSION}
ENV SPACK_ROOT=/opt/spack
ENV GNUPGHOME=${SPACK_ROOT}/opt/spack/gpg
ENV ENV_SPACK_TARGET=${SPACK_TARGET}
ENV ENV_COMPILERS_SPACK_MANIFEST=/opt/compilers.spack.yaml
ENV ENV_PACKAGES_SPACK_MANIFEST=/opt/packages.spack.yaml

# Export the repo versions for comparison in the runner target
ENV INITIAL_SPACK_CONFIG_REPO_VERSION=${SPACK_CONFIG_REPO_VERSION}
ENV INITIAL_SPACK_REPO_VERSION=${SPACK_REPO_VERSION}

LABEL au.org.access-nri.image.spack-repo-version=${SPACK_REPO_VERSION}
LABEL au.org.access-nri.image.spack-config-repo-version=${SPACK_CONFIG_REPO_VERSION}

SHELL ["/bin/bash", "-c"]

# Install spack
RUN <<EOF
git clone ${SPACK_GIT_URL} ${SPACK_ROOT} --branch ${SPACK_REPO_VERSION}

# Install ACCESS-NRIs spack-config repo
git clone  https://github.com/ACCESS-NRI/spack-config.git /opt/spack-config --branch ${SPACK_CONFIG_REPO_VERSION}
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

# Setup Spack environment for subsequent RUN steps
SHELL ["docker-shell"]

# https://spack.readthedocs.io/en/latest/bootstrapping.html
# Spack is configured to bootstrap its dependencies and repositories lazily by default;
# i.e. the first time they are needed and can't be found.

# Bootstrap spack and clone relevant spack-packages repos

# Currently, the version of spack-config informs the initial versions of the spack-packages repos to use.
# If we wanted to do it manually, add this post-bootstrap
#   builtin_spack_packages_sha=$(git -C $(spack location --repo builtin) rev-parse "${BUILTIN_SPACK_PACKAGES_REPO_VERSION}}^{}")
#   access_spack_packages_sha=$(git -C $(spack location --repo access.nri) rev-parse "${ACCESS_SPACK_PACKAGES_REPO_VERSION}}^{}")
#   spack repo update builtin --commit $builtin_spack_packages_sha
#   spack repo update access.nri --commit $access_spack_packages_sha
RUN spack bootstrap now

################################################################################
FROM base-spack AS dev

RUN <<EOF
spack install gcc@13.2.0 ~binutils target=x86_64
spack install intel-oneapi-compilers-classic@2021.10.0 target=x86_64
spack install intel-oneapi-compilers@2025.2.0 target=x86_64

case "$SPACK_VERSION" in
  v0*) spack load $(spack find --no-groups gcc intel-oneapi-compilers intel-oneapi-compilers-classic)
       spack compiler find
       git clone https://github.com/ACCESS-NRI/access-spack-packages.git /opt/spack-packages --branch api-v1
       git clone https://github.com/ACCESS-NRI/ACCESS-OM2 /opt/ACCESS-OM2 --branch api-v1
       ;;

  v1*) echo "Spack v1.x detects compilers directly"
       echo "spack-config v1.x manages access-spack-packages directly"
       git clone https://github.com/ACCESS-NRI/ACCESS-OM2 /opt/ACCESS-OM2
       ;;

  *) echo "Unknown Spack version"
     ;;
esac

spack env activate -p /opt/ACCESS-OM2
spack concretize -f
spack install
spack env deactivate

spack clean --downloads --stage
EOF

ENTRYPOINT ["/bin/bash", "/opt/spack/share/spack/docker/entrypoint.bash"]
CMD ["interactive-shell"]

################################################################################
FROM base-spack AS base-ci

# Install tmate in the image for remote access during workflows via mxschmitt/action-tmate
RUN <<EOF
curl -L https://github.com/tmate-io/tmate/releases/download/2.4.0/tmate-2.4.0-static-linux-amd64.tar.xz -o static-tmate.tar.xz
tar -xvf static-tmate.tar.xz --strip-components=1
mv tmate /usr/local/bin/tmate
rm -rf static-tmate.tar.xz
EOF

 # Install yq for manifest interrogation
RUN curl -L https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64 -o /usr/bin/yq && chmod +x /usr/bin/yq

################################################################################
# Install compilers and other common packages for the upstream image
FROM base-ci AS upstream

LABEL org.opencontainers.image.source=https://github.com/ACCESS-NRI/build-ci

# Install compilers and low-level, common packages
COPY ${SOURCE_COMPILERS_SPACK_MANIFEST} ${ENV_COMPILERS_SPACK_MANIFEST}
RUN --mount=type=secret,id=oci-username,env=OCI_USERNAME \
    --mount=type=secret,id=oci-password,env=OCI_PASSWORD \
    --mount=type=secret,id=oci-url,env=OCI_URL \
    <<EOF
if [ -n "$OCI_USERNAME" ] || [ -n "$OCI_PASSWORD" ] || [ -n "$OCI_URL" ]; then
  REQUESTS_OCI_MIRROR=1
  spack mirror add \
    --scope=site \
    --autopush \
    --unsigned \
    --oci-username-variable OCI_USERNAME \
    --oci-password-variable OCI_PASSWORD \
    docker_build_buildcache $OCI_URL
fi
spack mirror list

echo "Installing compilers"
spack env activate compilers --create --envfile ${ENV_COMPILERS_SPACK_MANIFEST}
spack install --deprecated --fail-fast || exit
spack env deactivate

spack clean --downloads --stage

if [ -n "$REQUESTS_OCI_MIRROR" ]; then
  spack mirror remove --scope=site docker_build_buildcache
fi
EOF

# Conditionally add mirrors based on whether secrets exist
COPY ${SOURCE_PACKAGES_SPACK_MANIFEST} ${ENV_PACKAGES_SPACK_MANIFEST}
RUN --mount=type=secret,id=oci-username,env=OCI_USERNAME \
    --mount=type=secret,id=oci-password,env=OCI_PASSWORD \
    --mount=type=secret,id=oci-url,env=OCI_URL \
    <<EOF

if [ -n "$OCI_USERNAME" ] || [ -n "$OCI_PASSWORD" ] || [ -n "$OCI_URL" ]; then
  REQUESTS_OCI_MIRROR=1
  spack mirror add \
    --scope=site \
    --autopush \
    --unsigned \
    --oci-username-variable OCI_USERNAME \
    --oci-password-variable OCI_PASSWORD \
    docker_build_buildcache $OCI_URL
fi
spack mirror list

echo "Installing common packages"
spack env activate packages --create --envfile ${ENV_PACKAGES_SPACK_MANIFEST}
spack install --deprecated --fail-fast || exit
spack env deactivate

spack clean --downloads --stage

if [ -n "$REQUESTS_OCI_MIRROR" ]; then
  spack mirror remove --scope=site docker_build_buildcache
fi
EOF

################################################################################
# Set up the lightweight spack image that uses the upstream image
FROM base-ci AS runner

LABEL org.opencontainers.image.source=https://github.com/ACCESS-NRI/build-ci

# Set up ACCESS Spack buildcache
RUN spack mirror add --scope=site --autopush --unsigned runner_set_buildcache /opt/runner_set_buildcache


ENTRYPOINT ["/bin/bash", "/opt/spack/share/spack/docker/entrypoint.bash"]
CMD ["interactive-shell"]
