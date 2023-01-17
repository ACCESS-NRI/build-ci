# ACCESS-NRI reusable CI workflows
A central repository for reusable github workflows and associated container defintions for CI across all ACCESS-NRI supported proejcts.

## Directory structure
### `.github/workflows`
All available reusable workflows. Naming convention: `[name of associated project repository]-[name of workflow].yml`. Subject to change once more generalised workflows are written. Unfortunately github currently disallows subdirectories in `.github/workflows`.

### `containers`
Build container definitions. Organised into subdirectories by name of associated project repository.

## Usage
### Simple example
`.github/workflows/workflow.yml`:

```
name: Example workflow

on:
  workflow_dispatch:
  pull_request:
  push:
    branches:
      - main

jobs:
  reusable-workflow-job:
    uses: access-nri/workflows/.github/workflows/example-workflow.yml@main
```

See [Reusing workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows#calling-a-reusable-workflow) for more info.
