# syntax-check

Runs WinCC OA syntax validation inside a Docker image that contains WinCC OA, Node.js, and npm.

## Runtime and compatibility

- This action supports Linux runners only.
- The current test baseline is Debian-based Docker images with WinCC OA 3.21.
- It is expected to work with WinCC OA 3.21 patch versions.
- It should also work with WinCC OA 3.22.
- Legacy WinCC OA 3.20 may work, but this is not guaranteed and should be validated in your environment.

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `path` | No | `.` | Project root relative to the repository root |
| `fail-on-error` | No | `true` | Fails the job when the checker returns an error |
| `docker-image` | No | `ghcr.io/winccoa-tools-pack/winccoa:latest` | Image used for the validation |
| `winccoa-version` | Yes | none | Installed WinCC OA version such as `3.21` |
| `config` | No | empty | Explicit config file path relative to the repository root |
| `mode` | No | `all` | `all`, `scripts`, or `panels` |
| `integrity` | No | `false` | Enables integrity checks |
| `timeout-ms` | No | `60000` | Validation timeout in milliseconds |
| `node-version` | No | `20.17.0` | Node.js version used when image has no node/npm |

## Outputs

| Output | Description |
| --- | --- |
| `error-count` | Best-effort parsed number of reported errors |

## Config handling

- If `config` is set and the file exists, the action uses that file.
- If `config` is empty, the action tries `<path>/config/config`.
- If no config file is found, the action generates a temporary minimal config,
  similar to the docs build flow, and continues.
- The action also starts `WCCILpmon` (best effort) and initializes SQLite DB
  with `WCCOAtoolCreateDbSQLite` when available.
- If `node`/`npm` are missing in the image, the action downloads a standalone
  Node.js Linux tarball from `nodejs.org` and installs it under `/usr/local`.
- The action prints grouped previews of captured stdout and stderr to simplify
  CI debugging.

## Example

```yaml
name: WinCC OA Syntax Check

on:
  push:
  pull_request:

jobs:
  syntax:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read

    steps:
      - uses: actions/checkout@v4

      - name: Run syntax check
        uses: winccoa-tools-pack/github-actions-winccoa/actions/syntax-check@v1
        with:
          path: .
          winccoa-version: '3.21'
          docker-image: ghcr.io/winccoa-tools-pack/winccoa:latest
          fail-on-error: 'true'
```
