# WinCC OA CTL Style Check

Thin GitHub Action wrapper around the public npm package
[`@winccoa-tools-pack/npm-winccoa-ctrl-code-style`](https://www.npmjs.com/package/@winccoa-tools-pack/npm-winccoa-ctrl-code-style).

Uses the **worker + StyleCheck** model:

1. Register bundled **StyleCheck** as a non-runnable sub-project
2. Register the **worker / source project** as runnable with StyleCheck attached
3. Run `WCCOActrl -config <worker>/config/config ... astyle.ctl <source>`

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
| `source-path` | No | empty | Optional CTL tree to scan (`-s`); defaults to `path` |
| `command` | No | `check` | `check` (dry-run) or `format` (in place) |
| `blacklist` | No | empty | Newline-separated repository-relative file/directory exclusions |
| `blacklist-file` | No | empty | Repository-relative UTF-8 path-list file |
| `show-diff` | No | `true` | Include unified original/formatted diffs in captured logs |
| `report-format` | No | empty | `sarif` or `gitlab`; requires `report-path` and a supporting npm release |
| `report-path` | No | empty | Generated report path relative to checkout root |
| `fail-on-error` | No | `true` | Fail the job when style operation fails |
| `winccoa-version` | Yes | - | Installed WinCC OA version such as `3.21` |
| `languages` | No | `en_US.utf8` | Locales for worker registration |
| `docker-image` | No | empty | Optional WinCC OA container image |
| `register-project` | No | `true` | Let the package register StyleCheck + worker |
| `timeout-ms` | No | `120000` | WCCOActrl timeout in milliseconds |
| `package-version` | No | `0.2.1` | npm version/dist-tag for ctrl-code-style |
| `log-path` | No | `.artifacts/style-check.log` | Captured log path |
| `node-version` | No | `22` | Node major when bootstrapping Node |

## Outputs

| Output | Description |
| --- | --- |
| `exit-code` | Style CLI exit code |
| `log-path` | Absolute path to the captured style log |
| `report-path` | Absolute host path to generated report; empty if none was produced |

## Blacklist and formatter diffs

These features require a release of the npm style package that includes
blacklist and diff support. They are **not available in 0.1.2 or earlier**.
The action defaults to the published `0.2.1` release. Explicit version pins in
consumer workflows override the action default and must be updated separately.

For a release with feature support:

```yaml
with:
  path: src/Squirt
  winccoa-version: '3.21'
  package-version: '0.2.1'
  blacklist: |
    # Temporary exception while investigating Linux formatting
    src/Squirt/scripts/gedi/projectView.ctl
    generated folder
  blacklist-file: .ctl-style-blacklist
  show-diff: 'true'
```

Both blacklist inputs are optional and can be combined. `blacklist` uses one
path per line, preserving spaces in paths and ignoring blank lines and lines
starting with `#`. Entries match exact files or directory descendants, not globs.
The action resolves these paths against the checkout, including `/workspace`
inside Docker, rather than the temporary npm installation directory.

`blacklist-file` is a path relative to the repository root. The package reads
its entries relative to the list file's directory; blank lines and `#` comment
lines are ignored. A missing list file fails the operation. Skipped files are
recorded as `SKIPPED-BLACKLIST` in the style log.

With a supporting package release, diffs are enabled by default and included in
the existing `log-path` output. Check mode formats temporary copies without
modifying source files. Set `show-diff: 'false'` to pass `--no-diff` and skip
the additional diagnostic formatter pass.

## Machine-Readable Reports

Use SARIF 2.1.0 for GitHub code scanning and Jenkins Warnings NG. Use GitLab
Code Quality JSON for GitLab merge-request reports. Reporting requires a new
supporting npm package release; it is not available in 0.1.2 or earlier. Pin
that release explicitly through `package-version`.

```yaml
- id: style
  continue-on-error: true
  uses: winccoa-tools-pack/github-actions-winccoa/actions/winccoa-style-check@main
  with:
    path: src/Squirt
    winccoa-version: '3.21'
    docker-image: ${{ vars.WINCCOA_IMAGE }}
    package-version: ${{ vars.STYLE_PACKAGE_VERSION }}
    report-format: sarif
    report-path: .artifacts/ctl-style.sarif
- if: always() && steps.style.outputs.report-path != ''
  uses: github/codeql-action/upload-sarif@v4
  with:
    sarif_file: ${{ steps.style.outputs.report-path }}
    category: winccoa-ctl-style
- if: always() && steps.style.outcome != 'success'
  run: exit 1
```

The job needs `security-events: write`, plus `contents: read` and `actions: read`
as appropriate. Private/internal repositories require GitHub Code Security.
Authenticate to private container registries and grant package access to the
consumer repository. Do not expose secrets to untrusted fork pull requests.

Both paths are resolved against the checkout, not the npm installation directory.
The action passes the checkout as `--report-root`; Docker writes the report into
the mounted checkout. `report-path` output points to the surviving host file,
even if formatting violations caused the operation to fail. It is empty when
execution failed without producing a report. Parent directories are created by
the package. The report destination is an owned output artifact, not a source
file; stale content is removed before execution.

Publish after failed checks using `always()` but keep the final failure gate.
Clean checks produce valid empty reports. Do not replace missing reports with
empty files: that hides execution failures. Keep the captured style log/diff as
an artifact. `show-diff: 'false'` suppresses console patches, not reports.

Reports describe original-source formatting regions with checkout-relative
paths, fingerprints and rule `winccoa.astyle.Formatting`. Blacklisted files are
omitted. Use `command: check` for CI: `format` reports changes it applied, not
remaining violations. Only one report format is requested per action call.

For GitLab, run the npm CLI directly with `--report-format gitlab` and declare
`artifacts:reports:codequality`. For Jenkins, import SARIF with
`recordIssues(enabledForFailure: true, tools: [sarif(pattern: '...')])`.
See the package's
[DevOps guide](https://github.com/winccoa-tools-pack/npm-winccoa-ctrl-code-style/blob/develop/docs/devops-reporting.md)
and its [GitHub](https://github.com/winccoa-tools-pack/npm-winccoa-ctrl-code-style/blob/develop/examples/github-sarif.yml),
[GitLab](https://github.com/winccoa-tools-pack/npm-winccoa-ctrl-code-style/blob/develop/examples/gitlab-code-quality.yml)
and [Jenkins](https://github.com/winccoa-tools-pack/npm-winccoa-ctrl-code-style/blob/develop/examples/Jenkinsfile)
examples for complete configurations and release prerequisites.

## Example

```yaml
name: WinCC OA CTL Style Check

on:
  push:
  pull_request:

jobs:
  style:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read
      pull-requests: write
    env:
      WINCCOA_IMAGE: ghcr.io/winccoa-tools-pack/winccoa-images:3.21.6-debian12-amd64-all
    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - run: docker pull "$WINCCOA_IMAGE"

      - id: style
        continue-on-error: true
        uses: winccoa-tools-pack/github-actions-winccoa/actions/winccoa-style-check@main
        with:
          path: src/Squirt
          source-path: src/Squirt/scripts
          winccoa-version: '3.21'
          docker-image: ${{ env.WINCCOA_IMAGE }}
          command: check
          languages: |
            en_US.utf8
          fail-on-error: 'true'
          package-version: '0.2.1'
          log-path: .artifacts/style-check.log

      - if: always() && github.event_name == 'pull_request'
        uses: winccoa-tools-pack/github-actions-winccoa/actions/winccoa-logs-to-pr-review@main
        with:
          log-path: ${{ steps.style.outputs.log-path }}
          title: CTL style check report
          comment-marker: '<!-- winccoa-style-check-report -->'
          include-error-types: CTRL
          review-comments: 'true'

      - if: steps.style.outcome == 'failure'
        run: exit 1
```

## Notes

- This action installs and runs the public npm CLI; it does not duplicate package logic
- Never pin npm packages to git branch names such as `@main`
- Registration and CTRL run in the **same** host/container so `pvssInst.conf` is shared
- StyleCheck is non-runnable and ships scripts only; logs stay on the worker project
- Full WCCOActrl output is written to `log-path` for `winccoa-logs-to-pr-review`
- Shell logic lives in `scripts/` (`run.sh`, `run-in-container.sh`, `lib.sh`)

## Validation

Run repository metadata validation and the focused shell tests:

```bash
npm run validate
npm run test:style-check
```

The shell tests use stub npm, Node and Docker commands; no installation,
container runtime, network access or WinCC OA project is required.

---

<!-- markdownlint-disable-next-line MD033 -->
<center>Made with ❤️ for and by the WinCC OA community</center>
