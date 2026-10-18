#!/usr/bin/env bash
# Shared helpers for winccoa-style-check action scripts.

normalize_rel_path() {
  local p="${1#./}"
  if [ -z "${p}" ]; then
    p="."
  fi
  printf '%s' "${p}"
}

normalize_langs() {
  printf '%s\n' "$1" | tr '\n' ' ' | xargs | tr ' ' ','
}

ensure_node() {
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    echo "Using existing Node $(node -v) / npm $(npm -v)"
    return 0
  fi
  local major="${NODE_VERSION:-22}"
  local arch
  case "$(uname -m)" in
    x86_64|amd64) arch="x64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      echo "::error::Unsupported architecture: $(uname -m)"
      exit 2
      ;;
  esac
  echo "Node/npm not found; installing Node ${major} (${arch}) from nodejs.org"
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl xz-utils >/dev/null
  fi
  local ver
  ver="$(curl -fsSL https://nodejs.org/dist/index.json | python3 -c "import json,sys; major=sys.argv[1]; data=json.load(sys.stdin); lts=[x['version'] for x in data if x['version'].startswith('v'+major+'.') and x.get('lts')]; cands=[x['version'] for x in data if x['version'].startswith('v'+major+'.')]; print((lts or cands)[0])" "${major}")"
  curl -fsSL "https://nodejs.org/dist/${ver}/node-${ver}-linux-${arch}.tar.xz" | tar -xJ -C /usr/local --strip-components=1
  hash -r || true
  echo "Installed Node $(node -v) / npm $(npm -v)"
}

# Run winccoa-ctrl-style against a worker project path in the current environment.
run_style_cli() {
  local project_path="$1"
  local source_path="${2:-}"
  local workspace="${GITHUB_WORKSPACE:-${PWD}}"
  local blacklist_args=()
  if [ -n "${REPORT_FORMAT:-}" ] || [ -n "${REPORT_PATH:-}" ]; then
    case "${REPORT_FORMAT:-}" in
      sarif|gitlab) ;;
      *) echo "::error::report-format must be sarif or gitlab"; return 2 ;;
    esac
    if [ -z "${REPORT_PATH:-}" ]; then
      echo "::error::report-path is required with report-format"
      return 2
    fi
    blacklist_args+=(--report-format "${REPORT_FORMAT}" --report-file "${workspace}/${REPORT_PATH#./}" --report-root "${workspace}")
  fi
  local excluded
  while IFS= read -r excluded || [ -n "${excluded}" ]; do
    excluded="${excluded%$'\r'}"
    excluded="${excluded#"${excluded%%[![:space:]]*}"}"
    excluded="${excluded%"${excluded##*[![:space:]]}"}"
    if [ -z "${excluded}" ] || [[ "${excluded}" == \#* ]]; then
      continue
    fi
    blacklist_args+=(--blacklist "${workspace}/${excluded#./}")
  done <<< "${BLACKLIST:-}"

  if [ -n "${BLACKLIST_FILE:-}" ]; then
    local blacklist_file="${workspace}/${BLACKLIST_FILE#./}"
    if [ ! -f "${blacklist_file}" ]; then
      echo "::error::Blacklist file does not exist: ${blacklist_file}"
      return 2
    fi
    blacklist_args+=(--blacklist-file "${blacklist_file}")
  fi

  case "${SHOW_DIFF:-true}" in
    true) ;;
    false) blacklist_args+=(--no-diff) ;;
    *)
      echo "::error::show-diff must be true or false"
      return 2
      ;;
  esac

  # CTL getFileNamesRecursive needs full absolute paths (not CWD-relative).
  if command -v realpath >/dev/null 2>&1; then
    project_path="$(realpath "${project_path}")"
    if [ -n "${source_path}" ]; then
      source_path="$(realpath "${source_path}")"
    fi
  else
    project_path="$(cd "${project_path}" && pwd -P)"
    if [ -n "${source_path}" ]; then
      if [ -d "${source_path}" ]; then
        source_path="$(cd "${source_path}" && pwd -P)"
      else
        source_path="$(cd "$(dirname "${source_path}")" && pwd -P)/$(basename "${source_path}")"
      fi
    fi
  fi

  ensure_node
  local workdir
  workdir="$(mktemp -d)"
  cd "${workdir}"
  npm init -y >/dev/null 2>&1
  echo "Installing ${PKG_SPEC}"
  npm install --silent --no-fund --no-audit "${PKG_SPEC}"

  local pkg_root="${workdir}/node_modules/@winccoa-tools-pack/npm-winccoa-ctrl-code-style"
  local entry="${pkg_root}/dist/cjs/cli.js"
  if [ ! -f "${entry}" ]; then
    echo "::error::Missing CLI entry ${entry}"
    ls -la "${pkg_root}" || true
    exit 2
  fi

  local cmd="${COMMAND:-check}"
  case "${cmd}" in
    check|format) ;;
    *)
      echo "::error::Invalid command '${cmd}'. Expected check or format."
      exit 2
      ;;
  esac

  local langs
  langs="$(normalize_langs "${LANGUAGES:-en_US.utf8}")"
  if [ -z "${langs}" ]; then
    echo "::error::languages resolved to an empty list"
    exit 2
  fi

  local args=(
    "${cmd}"
    "${project_path}"
    -v "${OA_VERSION}"
    --langs "${langs}"
    -t "${TIMEOUT_MS}"
  )

  if [ -n "${source_path}" ]; then
    args+=(-s "${source_path}")
  fi

  if [ "${REGISTER_PROJECT:-true}" != "true" ]; then
    args+=(--no-register)
  fi

  args+=("${blacklist_args[@]}")

  echo "Running: node ${entry} ${args[*]}"
  node "${entry}" "${args[@]}"
}
