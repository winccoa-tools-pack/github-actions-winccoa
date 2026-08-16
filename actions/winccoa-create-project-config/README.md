# WinCC OA Create Project Config

Creates and configures a WinCC OA project configuration file with support for multiple languages.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `project-path` | yes | - | Path to WinCC OA project(s). Space-separated for multiple projects (sub-projects, add-ons, plugins). Last path is the main project (e.g., `src/Squirt` or `addons/plugin1 src/Squirt`) |
| `languages` | yes | - | Languages to configure, space-separated full locale names (e.g., `en_US.utf8 de_AT.utf8`) |
| `winccoa-version` | yes | - | WinCC OA version (e.g., `3.21`) |
| `pmon-port` | no | `5999` | PMON port number |

## Behavior

- Creates a config directory at `{project-path}/config` (uses last path in project-path)
- Generates a WinCC OA config file with:
  - `pvss_path = "/opt/WinCC_OA/{winccoa-version}"`
  - Multiple `proj_path` entries (one per project path, supporting sub-projects and add-ons)
  - Multiple `langs` entries (one per language)
  - `proj_version = "{winccoa-version}"`
- Registers the project using `WCCILpmon -autofreg`

## Usage

```yaml
- uses: winccoa-tools-pack/github-actions-winccoa/actions/winccoa-create-project-config@main
  with:
    project-path: src/Squirt
    languages: en_US.utf8 de_AT.utf8
    winccoa-version: 3.21

# Or with multiple projects (sub-projects/add-ons):
- uses: winccoa-tools-pack/github-actions-winccoa/actions/winccoa-create-project-config@main
  with:
    project-path: addons/plugin1 src/Squirt
    languages: en_US.utf8 de_AT.utf8
    winccoa-version: 3.21
```

## Exit Code

- `0`: Success (config created and registered)
- `!= 0`: Error during config creation or registration

---

<center>Made with ❤️ for and by the WinCC OA community</center>
