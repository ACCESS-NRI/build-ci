# ACCESS-NRI reusable CI workflows
A central repository for reusable github workflows and associated container defintions for CI across all ACCESS-NRI supported proejcts.

## Directory structure
### `.github/workflows`
All available reusable workflows. Naming convention: `[name of associated project repository]-[name of workflow].yml`. Subject to change once more generalised workflows are written. Unfortunately github currently disallows subdirectories in `.github/workflows`.

### `containers`
Build container definitions. Organised into subdirectories by name of associated project repository.
