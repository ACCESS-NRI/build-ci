ARG MODEL_NAME

FROM spack/rockylinux8:v0.20.1 as builder
ARG MODEL_NAME
ARG SPACK_PACKAGES_REPO_VERSION


ENV SPACK_PACKAGES_REPO_ROOT=/opt/spack_packages
ENV SPACK_ENVIRONMENT_DIRECTORY_ROOT=/opt/spack_environment

WORKDIR $SPACK_ROOT

# Copy across the repos we use for dependencies
COPY ./repos.yaml $SPACK_ROOT/etc/spack/repos.yaml
#Clone spack_packages at the specified version
RUN git clone --depth 1 --branch ${SPACK_PACKAGES_REPO_VERSION} https://github.com/ACCESS-NRI/spack_packages.git ${SPACK_PACKAGES_REPO_ROOT}

COPY ./spack_environment/envs/${MODEL_NAME}.spack.yaml ${SPACK_ENVIRONMENT_DIRECTORY_ROOT}/${MODEL_NAME}.spack.yaml

# Setup buildcaching
RUN --mount=type=secret,id=S3_ACCESS_KEY_ID \
    --mount=type=secret,id=S3_ACCESS_KEY_SECRET \
    --mount=type=secret,id=access-nri.priv \
    --mount=type=secret,id=access-nri.pub \
    spack mirror add --s3-access-key-id `cat /run/secrets/S3_ACCESS_KEY_ID` --s3-access-key-secret `cat /run/secrets/S3_ACCESS_KEY_SECRET` s3_buildcache s3://access-nri-spack-cache \
 && spack gpg trust /run/secrets/access-nri.priv \
 && spack gpg trust /run/secrets/access-nri.pub    

# Setup environment
# ./setup-spack-envs 
RUN cd ${SPACK_ENVIRONMENT_DIRECTORY_ROOT} \
 && spack env create ${MODEL_NAME} ${MODEL_NAME}.spack.lock \
 && spack env activate ${MODEL_NAME} \
 && spack install --fail-fast \
 && spack compiler find --scope site

# RUN push buildcache
RUN spack -d buildcache create -a -m s3_buildcache ${SPACK_ENVIRONMENT_DIRECTORY_ROOT}/${MODEL_NAME}.spack.yaml

# clean up
RUN spack gc -y \
 && find -L /opt/view/* -type f -exec readlink -f '{}' \; | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip


FROM spack/rockylinux8:v0.20.1

ARG MODEL_NAME

COPY --from=builder /opt/spack_environment /opt/spack_environment
COPY --from=builder /opt/software /opt/software
COPY --from=builder /opt/._view /opt/._view
COPY --from=builder /opt/view /opt/view 

WORKDIR $SPACK_ROOT

CMD [ "spack", "activate", "env", "${MODEL_NAME}" ]

# Do we cache each env or the install itself?
# Env peculiarities?
# Saving of .lock and .spack.yaml files? In build-ci?