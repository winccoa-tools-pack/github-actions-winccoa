# WinCC OA Create Project Config

Creates and configures a WinCC OA project configuration file with support for multiple languages.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `project-path` | yes | - | Path to the WinCC OA project directory (e.g., `src/Squirt`) |
| `languages` | yes | - | Languages to configure, space-separated full locale names (e.g., `en_US.utf8 de_AT.utf8`) |
| `winccoa-version` | yes | - | WinCC OA version (e.g., `3.21`) |
| `pmon-port` | no | `5999` | PMON port number |

## Behavior

- Creates a config directory at `{project-path}/config`
- Generates a WinCC OA config file with:
  - `pvss_path = "/opt/WinCC_OA/{winccoa-version}"`
  - `proj_path = "{project-path}"`
  - `proj_version = "{winccoa-version}"`
  - `langs = "{languages}"` (space-separated)
  - `pmonPort = {pmon-port}`
- Registers the project using `WCCILpmon -autofreg`

## Usage

```yaml
- uses: winccoa-tools-pack/github-actions-winccoa/actions/winccoa-create-project-config@main
  with:
    project-path: src/Squirt
    languages: en_US.utf8 de_AT.utf8
    winccoa-version: 3.21
```

## Exit Code

- `0`: Success (config created and registered)
- `!= 0`: Error during config creation or registration

---

<center>Made with ❤️ for and by the WinCC OA community</center>
