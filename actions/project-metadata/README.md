# project-metadata

Normalizes WinCC OA project-related paths for downstream workflow steps.

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `path` | No | `.` | Project root relative to the repository root |
| `config` | No | empty | Explicit config file path. If omitted, resolves to `<path>/config/config` |

## Outputs

| Output | Description |
| --- | --- |
| `project-path` | Normalized project path |
| `config-path` | Resolved config path |

## Example

```yaml
- id: project
  uses: winccoa-tools-pack/github-actions-winccoa/actions/project-metadata@v1
  with:
    path: demo-oa-repo

- run: |
    echo "Project path: ${{ steps.project.outputs.project-path }}"
    echo "Config path: ${{ steps.project.outputs.config-path }}"
```
