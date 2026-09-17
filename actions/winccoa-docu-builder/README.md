# WinCC OA Docu Builder

Thin GitHub Action wrapper around the public npm package
[`@winccoa-tools-pack/npm-winccoa-docu-builder`](https://www.npmjs.com/package/@winccoa-tools-pack/npm-winccoa-docu-builder).

Uses the **worker + DocuBuilder** model:

1. Register bundled **DocuBuilder** as a non-runnable sub-project
2. Register the **worker / source project** as runnable with DocuBuilder attached
3. Optionally merge external **projectDocu** directories into
   `<path>/data/projectDocu`
4. Run `WCCOActrl -config <worker>/config/config ... buildHelp.ctl <CompanyName>`
5. Extract documentation warnings, emit PR annotations, optionally enforce a max count

## Runtime and compatibility

- Linux runners only
- Baseline: Debian-based Docker images with WinCC OA 3.21
- Expected to work with WinCC OA 3.21 patch versions and 3.22
- Provide either:
  - `docker-image` (recommended on GitHub-hosted runners), or
  - a job container / host that already has WinCC OA installed

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `path` | No | `.` | Runnable worker project root relative to repo root |
| `company-name` | No | empty | Company label; defaults to org/repo name |
| `fail-on-error` | No | `true` | Fail the job when docs build fails |
| `winccoa-version` | Yes | - | Installed WinCC OA version such as `3.21` |
| `languages` | No | `en_US.utf8` | Locales for worker registration |
| `project-docu-paths` | No | empty | Multi-line external projectDocu dirs (theme → project) |
| `docker-image` | No | empty | Optional WinCC OA container image |
| `register-project` | No | `true` | Let the package register DocuBuilder + worker |
| `timeout-ms` | No | `600000` | WCCOActrl timeout in milliseconds |
| `package-version` | No | `0.2.1` | npm version/dist-tag, or `github:owner/repo#ref` bootstrap spec |
| `log-path` | No | `.artifacts/docu-builder.log` | Captured log path |
| `warning-output-file` | No | `.artifacts/documentation-warnings.txt` | Extracted warnings file |
| `annotate-warnings` | No | `true` | Emit GitHub warning annotations |
| `max-warning-count` | No | `-1` | Fail when warnings exceed this (`-1` = off) |
| `max-annotations` | No | `200` | Cap for annotations |
| `install-doc-tooling` | No | empty | Optional install of required documentation tooling |
| `node-version` | No | `22` | Node major when bootstrapping Node |

### `project-docu-paths`

Ordered list of directories (relative to the repository root) whose **top-level
files** are merged into `<path>/data/projectDocu` before the build:

- the advanced config fragment is **concatenated** (later keys win)
- other files (`extra_header.html`, `extra_stylesheet.css`, …) use **last-wins**

Typical layering:

```yaml
project-docu-paths: |
  .documentation-theme
  .winccoa-docu-builder
```

Requires package **0.2.1+** (or a git bootstrap that includes `--project-docu`).

## Outputs

| Output | Description |
| --- | --- |
| `exit-code` | Docs CLI exit code |
| `log-path` | Absolute path to the captured docs log |
| `warning-count` | Number of extracted warning lines |
| `warning-file` | Path to the extracted warnings file |

## Example

```yaml
name: WinCC OA Docs

on:
  push:
  pull_request:

jobs:
  docs:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read
      pull-requests: write
    env:
      WINCCOA_IMAGE: ghcr.io/winccoa-tools-pack/winccoa:v3.21.3-debian12-all
    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - run: docker pull "$WINCCOA_IMAGE"

      - id: docs
        uses: winccoa-tools-pack/github-actions-winccoa/actions/winccoa-docu-builder@main
        with:
          path: src/Squirt
          winccoa-version: '3.21'
          docker-image: ${{ env.WINCCOA_IMAGE }}
          company-name: winccoa-tools-pack
          project-docu-paths: |
            .documentation-theme
            .winccoa-docu-builder
          package-version: '0.2.1'
          max-warning-count: '-1'
```

## Bootstrap before npm publish

Until `@winccoa-tools-pack/npm-winccoa-docu-builder` is published, you can pass a
git install spec:

```yaml
package-version: 'github:winccoa-tools-pack/npm-winccoa-docu-builder#feature/initial-docu-builder'
```

After the fix release, switch back to a semver such as `0.2.1`.

## Scope notes

- v1 builds documentation from the **runner/worker project only**.
- Test-suite source documentation can be added later.
- Annotations map `file:line[:col]: message` style tool output onto PR files
  when paths are present in the warning text.
- Warning extraction order: dedicated warning logfile, stderr log, stdout log,
  then process output fallback.
- After a successful build, the action stages debug files next to
  `warning-output-file` for artifact upload, including configuration fragments,
  generated merged configuration, and warning logs.

---

<center>Made with ❤️ for and by the WinCC OA community</center>
