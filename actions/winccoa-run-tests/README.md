# WinCC OA Run Tests

Executes WinCC OA tests using the TestFramework with automatic jUnit report generation and artifact uploads.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `project-path` | yes | - | Path to the Squirt project (e.g., `src/Squirt`) |
| `test-project-path` | yes | - | Path to the test project (e.g., `tests/WinCC_OA_Test`) |
| `test-run-id` | yes | - | Unique test run identifier (e.g., `Squirt-regression`) |
| `languages` | yes | - | Test languages, space-separated full locale names (e.g., `en_US.utf8 de_AT.utf8`) |
| `winccoa-version` | yes | - | WinCC OA version (e.g., `3.21`) |
| `pmon-port` | no | `5999` | PMON port number |
| `upload-artifacts` | no | `true` | Upload failed tests and results as artifacts |
| `publish-junit-report` | no | `true` | Publish jUnit report as GitHub check |

## Outputs

| Output | Description |
|--------|-------------|
| `test-count` | Total number of tests executed |
| `failure-count` | Number of test failures |
| `error-count` | Number of test errors |
| `junit-report-file` | Path to generated jUnit XML file |
| `failed-projects-path` | Path to failed projects directory (if any) |

## Behavior

1. **Setup** — Configures test project with language support
2. **Execution** — Runs `testRunner.ctl` via `WCCOActrl`
3. **Conversion** — Converts results to jUnit format via `oaTestParsers/jsonToJUnit.ctl`
4. **Parsing** — Extracts test counts and failures from jUnit XML
5. **Upload** (optional) — Uploads test results and failed projects as artifacts
6. **Report** (optional) — Publishes jUnit report as GitHub check

## Usage

```yaml
- uses: winccoa-tools-pack/github-actions-winccoa/actions/winccoa-run-tests@main
  with:
    project-path: src/Squirt
    test-project-path: tests/WinCC_OA_Test
    test-run-id: Squirt-regression
    languages: en_US.utf8 de_AT.utf8
    winccoa-version: 3.21
```

## Exit Code

- `0`: All tests passed
- `1`: Test failures or errors detected
- `!= 0`: Setup or execution error

## Artifacts

When `upload-artifacts: true` (default):

- **`test-results`** — Test output directory with jUnit XML and logs
- **`failed-tests`** — Failed test projects (if any)

---

<center>Made with ❤️ for and by the WinCC OA community</center>
