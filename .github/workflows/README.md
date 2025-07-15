# Entrypoint Workflows

## `ci.yml` - Build and Test Workflow Entrypoint

### Overview

This workflow handles building and running short CI tests on a given spack manifest. It offers customisation of `spack`, `spack-config` and `spack-packages`, and allows SSH access to the installation to the author of the PR.

### Inputs

| Name | Type | Description | Required | Default | Example |
| ---- | ---- | ----------- | -------- | ------- | ------- |
| `spack-manifest-path` | `string` (Path relative to component repository root) |  File path in the caller model component repository that contains the spack manifest jinja template to install | `true` | N/A | `".github/build/manifests/template/access-om2.spack.yaml.j2"`, `".github/some.spack.yaml"` |
| `spack-manifest-data-path`| `string` (Path relative to component repository root) | File path in the caller model component repository that contains jinja data to fill in to the spack manifest jinja template given by `inputs.spack-manifest-path`. This doesn't include the pull request ref (`{{ pr }}`), which is filled in automatically | `false` | N/A | `".github/build/data/template-data.json"` |
| `spack-compiler-manifest-path` | `string` (Path relative to component repository root) | A file path in the caller model component repository that contains the spack manifest to install local compilers not in the upstream | `false` | N/A | `".github/build/compilers/intel-2021.11.0.spack.yml"` |
| `ref` | `string` (Git ref) | The branch, tag, or commit SHA of the caller model component repository | `false` | `github.event.pull_request.head.sha` for PRs, `github.sha` otherwise | `"02125b01eb7c778c8d0ae0a02a260de474782e81"`, `"main"`, `"2025.01.000"` |
| `spack-config-ref` | `string` (Git ref) | The branch, tag, or commit SHA of the access-nri/spack-config repository to use | `false` | `"main"` | `"02125b01eb7c778c8d0ae0a02a260de474782e81"`, `"main"`, `"2025.01.000"` |
| `spack-packages-ref` | `string` (Git ref) | The branch, tag, or commit SHA of the access-nri/spack-packages repository to use | `false` | `"main"` | `"02125b01eb7c778c8d0ae0a02a260de474782e81"`, `"main"`, `"2025.01.000"` |
| `allow-ssh-into-spack-install` | `boolean` | Enable the actor of the workflow to SSH into the container where the spack packages have been installed. This is useful for gathering post-install information before the container is destroyed. This will also make the workflow wait until the actor SSHs into the container, or it times out, before continuing | `false` | `false` | `true`, `false` |

#### Future Inputs

| Name | Type | Description | Required | Default | Example |
| ---- | ---- | ----------- | -------- | ------- | ------- |
| `pytest-test-directory-path` | `string` (Directory path relative to component repository root) | Directory path in the caller model component repository that contains pytests to run against the built manifests | `false` | N/A | `".github/build/tests/"` |
| `pytest-test-markers` | `string` (Pytest-style markers) | A string of pytest markers to use to filter tests in the caller model component repository | `false` | `""` (runs all tests) | `"not slow and not mpi"` |

### Secrets

| Name | Type | Description | Required | Default | Example |
| ---- | ---- | ----------- | -------- | ------- | ------- |
| `spack-install-command-pat` | `string` (GitHub Personal Access Token) | GitHub PAT to use for the spack install command, for access to potentially private repositories | `false` | N/A | `"github_pat_XXXXX"` |

### Outputs

| Name | Type | Description | Example |
| ---- | ---- | ----------- | ------- |
| `spec-concretization-graph` | `string` (multiline) | A visual representation of the dependencies and constraints of the spack manifest file installed | N/A |
| `spack-sha` | `string` (Git commit SHA) | The SHA of the `ACCESS-NRI/spack` repository checked out | `"02125b01eb7c778c8d0ae0a02a260de474782e81"` |
| `spack-config-sha` | `string` (Git commit SHA) | The SHA of the `ACCESS-NRI/spack-config` repository checked out | `"02125b01eb7c778c8d0ae0a02a260de474782e81"` |
| `spack-packages-sha` | `string` (Git commit SHA) | The SHA of the `ACCESS-NRI/spack-packages` repository checked out | `"02125b01eb7c778c8d0ae0a02a260de474782e81"` |
| `sha` | `string` (Git commit SHA) | The SHA of the caller model component repository checked out | `"02125b01eb7c778c8d0ae0a02a260de474782e81"` |
| `spack-files-artifact-url` | `string` (URL) | The URL of the spack manifest and lock files artifact | `"https://github.com/ACCESS-NRI/MOM5/actions/runs/15890554355/artifacts/3406449135"` |

#### Future Outputs

| Name | Type | Description | Example |
| ---- | ---- | ----------- | ------- |
| `test-artifact-url` | `string` (URL) | The URL of the pytest result artifact | `"https://github.com/ACCESS-NRI/MOM5/actions/runs/15890554355/artifacts/3406449136"` |

### Examples

#### Minimal

```yaml
jobs:
  test:
    uses: access-nri/build-ci/.github/workflows/ci.yml@v2
    with:
      spack-manifest-path: .github/build/spack.yaml.j2
```

#### Complex

```yaml
jobs:
  test:
    uses: access-nri/build-ci/.github/workflows/ci.yml@v2
    with:
      spack-manifest-path: .github/build/spack.yaml.j2
      spack-manifest-data-path: .github/build/data/data.json
      spack-compiler-manifest-path: .github/build/compiler/intel.spack.yaml
      spack-ref: releases/v0.22
      spack-packages-ref: 2025.05.000
      spack-config-ref: 2025.10.001
      allow-ssh-into-spack-install: true
    secrets:
      spack-install-command-pat: ${{ secrets.GH_PAT }}
```

#### Simple Matrix

```yaml
jobs:
  test:
    strategy:
      fail-fast: false
      max-parallel: 2
      matrix:
        # Since it's just a single array of strings, we can do `matrix.manifest`
        manifest:
          - .github/build/one.spack.yaml.j2
          - .github/build/two.spack.yaml.j2
    uses: access-nri/build-ci/.github/workflows/ci.yml@v2
    with:
      spack-manifest-path: ${{ matrix.manifest }}
```

#### Complex Matrix

```yaml
jobs:
  test:
    strategy:
      fail-fast: false
      max-parallel: 2
      matrix:
        values:
          - manifest: .github/build/one.spack.yaml.j2
            compiler: .github/build/compiler/intel.spack.yaml
            pat: ${{ secrets.GH_PAT_FOR_MODEL1 }}
          - manifest: .github/build/two.spack.yaml.j2
            compiler: .github/build/compiler/gcc.spack.yaml
            pat: ${{ secrets.GH_PAT_FOR_MODEL2 }}
        # The above is a single array of objects, so we associate one parallel job with one manifest/compiler/pat with no combination taking place (eg, 2 jobs)
        # This is instead of multiple arrays of strings, eg.
        # matrix:
        #   manifest: [".github/build/one.spack.yaml.j2", ".github/build/two.spack.yaml.j2"]
        #   compiler: [".github/build/compiler/intel.spack.yaml", ".github/build/compiler/gcc.spack.yaml"]
        #   pat: ["${{ secrets.GH_PAT_FOR_MODEL1 }}", "${{ secrets.GH_PAT_FOR_MODEL2 }}"]
        # which would be a combination of all defined manifest/compilers (eg, 8 jobs)
    uses: access-nri/build-ci/.github/workflows/ci.yml@v2
    with:
      spack-manifest-path: ${{ matrix.values.manifest }}
      spack-compiler-manifest-path: ${{ matrix.values.compiler }}
    secrets:
      spack-install-command-pat: ${{ matrix.values.pat }}
```

### More Information

#### Jinja Templates and Data

The `inputs.spack-manifest-path` is a path to a jinja-templatable spack manifest.

It is jinja-templatable as we need a way to inject the `inputs.ref` into the caller model components `@git.VERSION` at build-time, as it is unknown at commit-time. This is why we use `{{ ref }}` in the spack manifest.

Since it is jinja-templatable, we also allow users to specify their own jinja template variables outside of `{{ ref }}` through the `inputs.spack-manifest-data-path`. This file can be quite simple:

```json
{
    "adjective": "cool",
    "compiler_version": "2025.10.0"
}
```

and you can reference the above in the manifest via `{{ adjective }}` and `{{ compiler_version }}` respectively, where they will be filled in at build-time. This can be used to define certain fields across spack manifests that are being built, in one place - for example, compiler flags.

The jinja data file (and the jinja-templatable spack manifest) can be much more complicated, but you will be responsible for making sure that it is templated into a valid spack manifest - see the [docs on jinja templates](https://jinja.palletsprojects.com/en/stable/templates/).

#### Compiler Spack Manifests

We use an upstream spack installation that contains common compilers used. If one wants to use other compilers that have not yet been added to that upstream spack, they can add a spack manifest that installs compilers before installing the given model component spack manifest, through `inputs.spack-compiler-manifest-path`.

This may increase the time for the CI tests to run, as the compiler will need to be installed every time (until we can cache compilers in the buildcache) but it can be used before the compiler is added to the upstream install.

A basic example is below:

```yaml
spack:
  specs:
  - intel-oneapi-compilers@2025.0.4 target=x86_64
  view: false
  concretizer:
    unify: false
```
