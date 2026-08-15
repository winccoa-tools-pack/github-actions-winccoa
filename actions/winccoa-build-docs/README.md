# winccoa-build-docs

Build WinCC OA help documentation inside a Docker container and extract Doxygen warnings.

## Inputs

- `path`: Project root path relative to repository root. Default `.`
- `winccoa-version`: WinCC OA version, for example `3.21`
- `docker-image`: WinCC OA container image, for example `ghcr.io/winccoa-tools-pack/winccoa:v3.21.3-debian12-all`
- `company-name`: Optional company/org string for `buildHelp.ctl`
- `warning-output-file`: Workspace-relative warning file path. Default `.artifacts/doxygen-warnings.txt`
- `annotate-warnings`: Emit warnings as GitHub annotations. Default `true`
- `max-warning-count`: Maximum allowed warning count. Use `-1` to disable threshold enforcement
- `max-annotations`: Maximum number of warning annotations to emit. Default `200`

## Outputs

- `warning-count`: Count of extracted warning lines
- `warning-file`: Path to extracted warning file

## Usage

```yaml
- name: Build docs
  id: docs
  uses: winccoa-tools-pack/github-actions-winccoa/actions/winccoa-build-docs@main
  with:
    path: src/Squirt
    winccoa-version: 3.21
    docker-image: ghcr.io/winccoa-tools-pack/winccoa:v3.21.3-debian12-all
    warning-output-file: .artifacts/doxygen-warnings.txt
    max-warning-count: 0
```

## Notes

- The caller workflow should login to `ghcr.io` first when the image is private.
- The action mounts both the repository workspace and action folder into the container.
- The helper script `buildHelp.ctl` is bundled with the action and invoked from `/action/buildHelp.ctl`.
