#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

resolve_workspace_path() {
  local raw_path="${1:-}"
  local workspace_root="${GITHUB_WORKSPACE:-/workspace}"

  if [ -z "${raw_path}" ]; then
    return 1
  fi

  if [[ "${raw_path}" = /* ]]; then
    printf '%s\n' "${raw_path}"
  else
    printf '%s\n' "${workspace_root}/${raw_path}"
  fi
}

restore_workspace_permissions() {
  if [ -z "${HOST_UID:-}" ] || [ -z "${HOST_GID:-}" ]; then
    return 0
  fi
  if ! command -v chown >/dev/null 2>&1; then
    return 0
  fi

  local target=""
  local resolved=""
  local targets=(
    "${GITHUB_WORKSPACE:-/workspace}/.artifacts"
    "${PROJECT_PATH_IN_CONTAINER}/log"
    "${PROJECT_PATH_IN_CONTAINER}/help"
    "${PROJECT_PATH_IN_CONTAINER}/data/projectDocu"
  )

  for target in "${LOG_PATH:-}" "${WARNING_OUTPUT_FILE:-}"; do
    [ -z "${target}" ] && continue
    resolved="$(resolve_workspace_path "${target}")" || continue
    targets+=("$(dirname "${resolved}")")
    targets+=("${resolved}")
  done

  for target in "${targets[@]}"; do
    [ -e "${target}" ] || continue
    chown -R "${HOST_UID}:${HOST_GID}" "${target}" || true
  done
}

if [ ! -d "/opt/WinCC_OA/${OA_VERSION}" ]; then
  echo "::error::WinCC OA install not found at /opt/WinCC_OA/${OA_VERSION}"
  exit 2
fi

PROJECT_PATH_IN_CONTAINER="${PROJECT_PATH_IN_CONTAINER:-}"
if [ -z "${PROJECT_PATH_IN_CONTAINER}" ]; then
  echo "::error::PROJECT_PATH_IN_CONTAINER is required inside the container"
  exit 2
fi

if [ ! -d "${PROJECT_PATH_IN_CONTAINER}" ]; then
  echo "::error::Project path does not exist: ${PROJECT_PATH_IN_CONTAINER}"
  exit 2
fi

trap restore_workspace_permissions EXIT

COMPANY_NAME="${COMPANY_NAME:-}"
if [ -z "${COMPANY_NAME}" ]; then
  COMPANY_NAME="$(resolve_company_name "")"
fi

set +e
OUTPUT=$(run_docu_cli "${PROJECT_PATH_IN_CONTAINER}" "${COMPANY_NAME}" 2>&1)
EC=$?
set -e

printf '%s\n' "${OUTPUT}"
echo "exit-code=${EC}"
exit "${EC}"
