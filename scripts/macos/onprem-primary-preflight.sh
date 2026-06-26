#!/usr/bin/env bash
set -euo pipefail

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

base_url="http://127.0.0.1:8080"
env_file=""
skip_http="false"
require_full_env="false"
run_id="$(date +%Y%m%d-%H%M%S)"
run_dir="${ONMU_ONPREM_REHEARSAL_DIR:-$HOME/.codex/local/ONMU/onprem-full-migration/preflight-$run_id}"

usage() {
  cat <<'EOF'
Usage: scripts/macos/onprem-primary-preflight.sh [options]

Options:
  --base-url <url>       API base URL to smoke. Default: http://127.0.0.1:8080
  --env-file <path>      Optional local-only env file to source. Values are never printed.
  --run-dir <path>       Output directory. Default: ~/.codex/local/ONMU/onprem-full-migration/preflight-<timestamp>
  --skip-http            Skip HTTP smoke.
  --require-full-env     Mark provider/OAuth/notification missing env names as No-Go in the summary.
  -h, --help             Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base-url)
      base_url="${2:?missing value for --base-url}"
      shift 2
      ;;
    --env-file)
      env_file="${2:?missing value for --env-file}"
      shift 2
      ;;
    --run-dir)
      run_dir="${2:?missing value for --run-dir}"
      shift 2
      ;;
    --skip-http)
      skip_http="true"
      shift
      ;;
    --require-full-env)
      require_full_env="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

mkdir -p "$run_dir"
report="$run_dir/onprem-primary-preflight.md"
events="$run_dir/onprem-primary-preflight.events.tsv"
: > "$events"

write_event() {
  local category="$1"
  local name="$2"
  local status="$3"
  local detail="${4:-}"
  printf '%s\t%s\t%s\t%s\n' "$category" "$name" "$status" "$detail" >> "$events"
}

if [ -n "$env_file" ]; then
  if [ ! -f "$env_file" ]; then
    write_event "env-file" "$env_file" "missing" "file_not_found"
  else
    # shellcheck disable=SC1090
    set -a
    source "$env_file"
    set +a
    write_event "env-file" "$env_file" "present" "sourced_without_printing_values"
  fi
fi

tool_status="ok"
for tool in git java docker curl; do
  if command -v "$tool" >/dev/null 2>&1; then
    write_event "tool" "$tool" "present" "$(command -v "$tool")"
  else
    tool_status="missing"
    write_event "tool" "$tool" "missing" "not_in_path"
  fi
done

for optional_tool in pg_dump pg_restore psql openssl; do
  if command -v "$optional_tool" >/dev/null 2>&1; then
    write_event "optional-tool" "$optional_tool" "present" "$(command -v "$optional_tool")"
  else
    write_event "optional-tool" "$optional_tool" "missing" "install_before_db_or_tls_rehearsal"
  fi
done

branch="$(git -C "$repo_root" branch --show-current 2>/dev/null || true)"
head="$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || true)"
dirty="$(git -C "$repo_root" status --short 2>/dev/null | wc -l | tr -d ' ')"
write_event "git" "branch" "${branch:-unknown}" "head=${head:-unknown}"
write_event "git" "dirty-count" "$dirty" "uncommitted_files"

runtime_env=(
  SPRING_DATASOURCE_URL
  SPRING_DATASOURCE_PASSWORD
  SPRING_DATA_REDIS_URL
  ONMU_ACCESS_TOKEN_SECRET
  OBJECT_STORAGE_ENDPOINT
  OBJECT_STORAGE_BUCKET
)

provider_env=(
  KAKAO_REST_API_KEY
  KAKAO_CLIENT_SECRET
  KAKAO_OAUTH_REDIRECT_URI
  KAKAO_OAUTH_MOBILE_CALLBACK_URI
  NAVER_OAUTH_CLIENT_ID
  NAVER_OAUTH_CLIENT_SECRET
  NAVER_OAUTH_REDIRECT_URI
  NAVER_OAUTH_MOBILE_CALLBACK_URI
  GOOGLE_OAUTH_CLIENT_ID
  GOOGLE_SERVER_CLIENT_ID
  NAVER_SEARCH_CLIENT_ID
  NAVER_SEARCH_CLIENT_SECRET
  OPENROUTESERVICE_API_KEY
)

notification_env=(
  ONMU_FCM_SERVICE_ACCOUNT_JSON
  ONMU_APNS_PRIVATE_KEY
  ONMU_APNS_KEY_ID
  ONMU_APNS_TEAM_ID
  ONMU_APNS_BUNDLE_ID
  ONMU_PUSH_PROVIDER_MODE
)

missing_runtime=0
for name in "${runtime_env[@]}"; do
  if [ -n "${!name:-}" ]; then
    write_event "runtime-env" "$name" "present" "value_redacted"
  else
    missing_runtime=$((missing_runtime + 1))
    write_event "runtime-env" "$name" "missing" "value_not_loaded"
  fi
done

missing_provider=0
for name in "${provider_env[@]}"; do
  if [ -n "${!name:-}" ]; then
    write_event "provider-env" "$name" "present" "value_redacted"
  else
    missing_provider=$((missing_provider + 1))
    write_event "provider-env" "$name" "missing" "value_not_loaded"
  fi
done

missing_notification=0
for name in "${notification_env[@]}"; do
  if [ -n "${!name:-}" ]; then
    write_event "notification-env" "$name" "present" "value_redacted"
  else
    missing_notification=$((missing_notification + 1))
    write_event "notification-env" "$name" "missing" "value_not_loaded"
  fi
done

http_status="skipped"
if [ "$skip_http" != "true" ]; then
  root="${base_url%/}"
  for path in /healthz /readyz /api/v1/users/me; do
    code="$(curl -sS -o /dev/null -w '%{http_code}' "$root$path" 2>/dev/null || printf '000')"
    expected="200"
    if [ "$path" = "/api/v1/users/me" ]; then
      expected="401"
    fi
    if [ "$code" = "$expected" ]; then
      write_event "http" "$path" "ok" "status=$code"
    else
      http_status="failed"
      write_event "http" "$path" "unexpected" "status=$code expected=$expected"
    fi
  done
  if [ "$http_status" != "failed" ]; then
    http_status="ok"
  fi
fi

env_status="ok"
if [ "$missing_runtime" -gt 0 ]; then
  env_status="runtime-missing"
fi
if [ "$require_full_env" = "true" ] && [ "$missing_provider" -gt 0 ]; then
  env_status="provider-missing"
fi
if [ "$require_full_env" = "true" ] && [ "$missing_notification" -gt 0 ]; then
  env_status="notification-missing"
fi

decision="GO"
if [ "$tool_status" != "ok" ] || [ "$env_status" != "ok" ] || [ "$http_status" = "failed" ]; then
  decision="NO-GO"
fi

{
  echo "# ONMU on-prem primary preflight"
  echo
  echo "- run id: \`$run_id\`"
  echo "- repo: \`$repo_root\`"
  echo "- branch: \`${branch:-unknown}\`"
  echo "- head: \`${head:-unknown}\`"
  echo "- dirty count: \`$dirty\`"
  echo "- base url: \`$base_url\`"
  echo "- decision: \`$decision\`"
  echo
  echo "## Summary"
  echo
  echo "- tool status: \`$tool_status\`"
  echo "- runtime env missing count: \`$missing_runtime\`"
  echo "- provider env missing count: \`$missing_provider\`"
  echo "- notification env missing count: \`$missing_notification\`"
  echo "- http status: \`$http_status\`"
  echo
  echo "## Events"
  echo
  echo "| category | name | status | detail |"
  echo "| --- | --- | --- | --- |"
  while IFS=$'\t' read -r category name status detail; do
    echo "| \`$category\` | \`$name\` | \`$status\` | \`$detail\` |"
  done < "$events"
  echo
  echo "## Secret Safety"
  echo
  echo "No secret values, OAuth code/state/idToken, bearer token, DB password, or user raw data are printed by this report."
} > "$report"

echo "report=$report"
echo "events=$events"
echo "decision=$decision"

if [ "$decision" != "GO" ]; then
  exit 1
fi
