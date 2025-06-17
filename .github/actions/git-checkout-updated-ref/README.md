# Update Existing Repo and Checkout Ref

Action that updates an existing repository, and checks out the updated ref.

## Inputs

| Name | Type | Description | Required | Default | Example |
| ---- | ---- | ----------- | -------- | ------- | ------- |
| `repository-path` | `string` (path) | The path to the repository to update and check out the ref | `true` | `"."` | `"$SPACK_ROOT/../spack-packages"` |
| `ref` | `string` (git branch, tag or sha) | The git ref to check out | `true` | N/A | `"main"` or `"v1"` or `"f8r73g3"` |

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
    steps:
    - uses: actions/checkout@v4

    - run: sleep 10000  # Maybe some updates will happen to the remote by the end of this...

    - uses: ./.github/actions/git-checkout-updated-ref
      with:
        repository-path: .
        ref: v2
```
