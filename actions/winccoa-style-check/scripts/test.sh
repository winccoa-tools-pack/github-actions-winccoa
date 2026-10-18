#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"
temporary="$(mktemp -d)"
export TMPDIR="${temporary}"
trap 'rm -rf "${temporary}"' EXIT
workspace="${temporary}/workspace with spaces"
mkdir -p "${workspace}/src/scripts" "${workspace}/config"
printf 'src/scripts/excluded.ctl\n' > "${workspace}/config/blacklist.txt"

ensure_node() { :; }
npm() {
  if [ "$1" = install ]; then
    mkdir -p node_modules/@winccoa-tools-pack/npm-winccoa-ctrl-code-style/dist/cjs
    touch node_modules/@winccoa-tools-pack/npm-winccoa-ctrl-code-style/dist/cjs/cli.js
  fi
}
node() { printf '%s\n' "$@" > "${CAPTURE}"; }

assert_arg() {
  if ! grep -Fx -- "$1" "${CAPTURE}" >/dev/null; then
    printf 'Missing argument: %s\n' "$1" >&2
    exit 1
  fi
}

export GITHUB_WORKSPACE="${workspace}"
export OA_VERSION=3.21 TIMEOUT_MS=120000 PKG_SPEC=test-package
export CAPTURE="${temporary}/args"

(
  cd "${temporary}"
  BLACKLIST=$'# comment\r\n\n  src/scripts/projectView.ctl  \r\ngenerated folder'
  BLACKLIST_FILE=config/blacklist.txt
  SHOW_DIFF=false REGISTER_PROJECT=false
  REPORT_FORMAT=sarif REPORT_PATH='reports/style report.sarif'
  run_style_cli "${workspace}/src" "${workspace}/src/scripts"
)
assert_arg --blacklist
assert_arg "${workspace}/src/scripts/projectView.ctl"
assert_arg "${workspace}/generated folder"
assert_arg --blacklist-file
assert_arg "${workspace}/config/blacklist.txt"
assert_arg --no-diff
assert_arg --no-register
assert_arg --report-format
assert_arg sarif
assert_arg --report-file
assert_arg "${workspace}/reports/style report.sarif"
assert_arg --report-root
assert_arg "${workspace}"
if grep -F '# comment' "${CAPTURE}"; then exit 1; fi

(
  BLACKLIST='' BLACKLIST_FILE='' SHOW_DIFF=true
  run_style_cli "${workspace}/src" ''
)
if grep -E '^--(blacklist|blacklist-file|no-diff)$' "${CAPTURE}"; then exit 1; fi

if (BLACKLIST_FILE=missing.txt; run_style_cli "${workspace}/src" ''); then
  echo 'Expected missing blacklist file to fail' >&2
  exit 1
fi
if (SHOW_DIFF=invalid; run_style_cli "${workspace}/src" ''); then
  echo 'Expected invalid show-diff to fail' >&2
  exit 1
fi

docker() {
  printf '%s\n' "$@" > "${CAPTURE}"
  printf '[]\n' > "${GITHUB_WORKSPACE}/style.json"
  printf '%s\n' '--- original' '+++ formatted' '@@ -1 +1 @@' '-old' '+new'
}
(
  PROJECT_PATH=src SOURCE_PATH=src/scripts COMMAND=check PACKAGE_VERSION=next
  DOCKER_IMAGE=test-image BLACKLIST=$'src/scripts/projectView.ctl\ngenerated folder'
  BLACKLIST_FILE=config/blacklist.txt SHOW_DIFF=false
  REPORT_FORMAT=gitlab REPORT_PATH=style.json
  LOG_PATH=style.log GITHUB_OUTPUT="${temporary}/outputs"
  source "${SCRIPT_DIR}/run.sh"
)
assert_arg GITHUB_WORKSPACE=/workspace
assert_arg 'BLACKLIST=src/scripts/projectView.ctl'
assert_arg 'generated folder'
assert_arg BLACKLIST_FILE=config/blacklist.txt
assert_arg SHOW_DIFF=false
assert_arg REPORT_FORMAT=gitlab
assert_arg REPORT_PATH=style.json
grep -Fx -- '+++ formatted' "${workspace}/style.log" >/dev/null
grep -Fx 'exit-code=0' "${temporary}/outputs" >/dev/null
grep -Fx "report-path=${workspace}/style.json" "${temporary}/outputs" >/dev/null

docker() { printf '%s\n' 'formatter execution failed'; return 2; }
(
  PROJECT_PATH=src SOURCE_PATH=src/scripts COMMAND=check PACKAGE_VERSION=next
  DOCKER_IMAGE=test-image REPORT_FORMAT=gitlab REPORT_PATH=style.json
  FAIL_ON_ERROR=false LOG_PATH=failed-style.log GITHUB_OUTPUT="${temporary}/failed-outputs"
  source "${SCRIPT_DIR}/run.sh"
)
test ! -e "${workspace}/style.json"
grep -Fx 'report-path=' "${temporary}/failed-outputs" >/dev/null
grep -Fx 'exit-code=2' "${temporary}/failed-outputs" >/dev/null

echo 'Style action forwarding tests passed.'