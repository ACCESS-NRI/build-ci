# Setup Container Instance

Action that prepares a build-ci runner container instance for CI by exporting key environment variables, updating repositories to requested refs, and configuring Spack mirrors/upstreams where required.

## Inputs

| Name | Type | Description | Required | Default | Example |
| ---- | ---- | ----------- | -------- | ------- | ------- |
| `spack-ref` | `string` (git branch, tag or sha) | The git ref to checkout for the `spack` repository. | `true` | N/A | `"develop"` or `"v1.0.0"` or `"5a1cdc4e"` or `""` |
| `spack-config-ref` | `string` (git branch, tag or sha) | The git ref to checkout for the `spack-config` repository. | `true` | N/A | `"main"` or `"v0.5.2"` or `"3f14e99"` or `""` |
| `builtin-spack-packages-ref` | `string` (git branch, tag or sha) | The git ref to checkout for the builtin spack packages repository. | `true` | N/A | `"develop"` or `"release-1.2"` or `"a8b7c6d"` or `""` |
| `access-spack-packages-ref` | `string` (git branch, tag or sha) | The git ref to checkout for the `access-spack-packages` repository. | `true` | N/A | `"main"` or `"v2026.04"` or `"9e72b1c"` or `""` |
| `spack-oci-buildcache-url` | `string` (URL) | The OCI registry URL to add as a Spack buildcache mirror. Pass an empty string (`''`) to skip adding an OCI mirror. | `true` | N/A | `"ghcr.io/access-nri/spack-buildcache"` or `""` |
| `run-self-hosted` | `string` (boolean) | Whether this instance is running on a self-hosted runner. Controls upstream disabling and runner-set buildcache setup. | `true` | N/A | `"true"` or `"false"` |

## Outputs

| Name | Type | Description | Example |
| ---- | ---- | ----------- | ------- |
| `SPACK_ROOT` | `string` (path) | The Spack instance root path exported from the container environment. | `"/opt/spack"` |
| `INITIAL_SPACK_REPO_VERSION` | `string` | The initial Spack repository version before any updates. | `"releases/v1.0"` |
| `spack-env-dir` | `string` (path) | Absolute path to the runner environments directory used for artifact collection. | `"/opt/runner/environments"` |
| `spack-config-sha` | `string` (sha) | The git SHA checked out for the `spack-config` repository. | `"5a1cdc4e4617fcd6ba1cccf1cd0432b5631983be"` |
| `spack-sha` | `string` (sha) | The git SHA checked out for the `spack` repository. | `"d4e2fb7636e9ef3a8ebcf0f36f7f076f605ed87c"` |
| `builtin-spack-packages-sha` | `string` (sha) | The git SHA checked out for the builtin spack packages repository. | `"4319878c9a9714f938df8f9a58d4f79aece39b7b"` |
| `access-spack-packages-sha` | `string` (sha) | The git SHA checked out for the `access-spack-packages` repository. | `"77f9026d7e18bd4a0f9524f4b8a1e6f3f2345c9a"` |

## Examples

### Simple

```yaml
# ...
jobs:
  setup:
    runs-on: ubuntu-latest
    container:
      image: access-nri/build-ci-runner:rocky
    steps:
    - id: instance
      uses: access-nri/build-ci/.github/actions/setup-instance@v3
      with:
        spack-ref: releases/v1.1
        spack-config-ref: main
        builtin-spack-packages-ref: develop
        access-spack-packages-ref: api-v2
        spack-oci-buildcache-url: oci://ghcr.io/ACCESS-NRI/build-ci-buildcache
        run-self-hosted: false

    - run: echo "Spack root is ${{ steps.instance.outputs.SPACK_ROOT }}"
```
