# Update Existing Repo and Checkout Ref

Action that updates an existing repository, and checks out the updated ref.

## Inputs

| Name | Type | Description | Required | Default | Example |
| ---- | ---- | ----------- | -------- | ------- | ------- |
| `spack-packages-repository-name` | `string` | The name of the repository used by spack to update and checkout the ref (given in the spack config file `repos.yaml`) | `true` | N/A | `"builtin"` |
| `spack-packages-repository-path` | `string` (path) | The path to the repository to update and check out the ref | `true` | N/A | `"/root/.spack/package_repos/fncqgg4/repos/spack_repo/builtin"` |
| `ref` | `string` (git branch, tag or sha) | The git ref to check out | `true` | N/A | `"main"` or `"v1"` or `"f8r73g3"` |
| `spack-instance-root-path` | `string` (path) | The path to the spack instance root, used to setup the spack environment | `true` | N/A | `"/opt/spack"` |

## Outputs

| Name | Type | Description | Example |
| ---- | ---- | ----------- | ------- |
| `sha` | `string` (sha) | The SHA of the checked out ref | `"5a1cdc4e4617fcd6ba1cccf1cd0432b5631983be"` |
| `updated` | `string` (boolean) | Whether there was actually an update to the ref | `"true"` or `"false"` |

## Examples

### Simple

```yaml
# ...
jobs:
  update-repo:
    runs-on: ubuntu-latest
    env:
      SPACK_ROOT: /opt/spack
    steps:
    - id: repo
      run: |
        . ${{ env.SPACK_ROOT }}/share/spack/setup-env.sh
        echo "path=$(spack location --repo builtin)" >> $GITHUB_OUTPUT

    - id: update
      uses: ./.github/actions/spack-checkout-updated-ref
      with:
        spack-packages-repository-name: builtin
        spack-packages-repository-path: ${{ steps.repo.outputs.path }}
        ref: develop
        spack-instance-root-path: ${{ env.SPACK_ROOT }}

    - run: echo "The builtin spack-packages repo was updated to ${{ steps.update.outputs.sha }}"
```
