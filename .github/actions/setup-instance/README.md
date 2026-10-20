# Setup Container Instance

Action that prepares a build-ci runner container instance for CI by exporting key environment variables, updating repositories to requested refs, and configuring Spack mirrors/upstreams where required.

## Inputs

| Name | Type | Description | Required | Default | Example |
| ---- | ---- | ----------- | -------- | ------- | ------- |
| `spack-ref` | `string` (git branch, tag or sha) | The git ref to checkout for the `spack` repository. | `true` | N/A | `"develop"` or `"v1.0.0"` or `"5a1cdc4e"` or `""` |
| `spack-config-ref` | `string` (git branch, tag or sha) | The git ref to checkout for the `spack-config` repository. | `true` | N/A | `"main"` or `"v0.5.2"` or `"3f14e99"` or `""` |
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
      uses: access-nri/build-ci/.github/actions/setup-instance@v4
      with:
        spack-ref: releases/v1.1
        spack-config-ref: main
        spack-oci-buildcache-url: oci://ghcr.io/ACCESS-NRI/build-ci-buildcache
        run-self-hosted: false

    - run: echo "Spack root is ${{ steps.instance.outputs.SPACK_ROOT }}"
```
