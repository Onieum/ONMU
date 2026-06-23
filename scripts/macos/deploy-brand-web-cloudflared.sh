#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
site_dir="${ONMU_BRAND_SITE_DIR:-"$repo_root/apps/brand-web"}"
deploy_dir="${ONMU_BRAND_DEPLOY_DIR:-"$HOME/.codex/local/ONMU/brand-web/deploy/current"}"
log_dir="${ONMU_BRAND_LOG_DIR:-"$HOME/.codex/local/ONMU/brand-web/logs"}"
run_dir="${ONMU_BRAND_RUN_DIR:-"$HOME/.codex/local/ONMU/brand-web/run"}"
host="${ONMU_BRAND_HOST:-127.0.0.1}"
port="${ONMU_BRAND_PORT:-4173}"
domain="${ONMU_BRAND_DOMAIN:-onmu.cloud}"
tunnel_name="${ONMU_BRAND_TUNNEL_NAME:-onmu-brand-web}"
config_file="${ONMU_BRAND_CLOUDFLARED_CONFIG:-"$repo_root/infra/cloudflare/cloudflared-brand-web.yml"}"
local_url="http://$host:$port"

http_pid_file="$run_dir/brand-web-http.pid"
cloudflared_pid_file="$run_dir/brand-web-cloudflared.pid"
http_log="$log_dir/brand-web-http.log"
cloudflared_log="$log_dir/brand-web-cloudflared.log"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

stop_pid_file() {
  local pid_file="$1"
  if [[ ! -f "$pid_file" ]]; then
    return
  fi

  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    kill "$pid"
    sleep 1
  fi
  rm -f "$pid_file"
}

has_cloudflared_origin_cert() {
  [[ -n "${TUNNEL_ORIGIN_CERT:-}" && -f "${TUNNEL_ORIGIN_CERT:-}" ]] && return 0
  [[ -f "$HOME/.cloudflared/cert.pem" ]] && return 0
  [[ -f "$HOME/.cloudflare-warp/cert.pem" ]] && return 0
  [[ -f "$HOME/cloudflare-warp/cert.pem" ]] && return 0
  [[ -f "/etc/cloudflared/cert.pem" ]] && return 0
  [[ -f "/usr/local/etc/cloudflared/cert.pem" ]] && return 0
  return 1
}

require_command cloudflared
require_command curl
require_command python3

if [[ ! -d "$site_dir" ]]; then
  echo "Brand site directory not found: $site_dir" >&2
  exit 1
fi

if [[ ! -f "$config_file" ]]; then
  echo "Cloudflared config file not found: $config_file" >&2
  exit 1
fi

mkdir -p "$deploy_dir" "$log_dir" "$run_dir"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete --exclude README.md "$site_dir"/ "$deploy_dir"/
else
  rm -rf "$deploy_dir"
  mkdir -p "$deploy_dir"
  cp -R "$site_dir"/. "$deploy_dir"/
fi
rm -f "$deploy_dir/README.md"

python3 - "$deploy_dir/brand-config.js" <<'PY'
import json
import os
import sys

target = sys.argv[1]
dsn = os.environ.get("ONMU_BRAND_SENTRY_DSN") or os.environ.get("SENTRY_DSN") or ""
config = {
    "sentryDsn": dsn.strip(),
    "sentryEnvironment": (
        os.environ.get("ONMU_BRAND_SENTRY_ENVIRONMENT")
        or os.environ.get("SENTRY_ENVIRONMENT")
        or os.environ.get("ONMU_ENV")
        or "production"
    ).strip(),
    "sentryRelease": (
        os.environ.get("ONMU_BRAND_SENTRY_RELEASE")
        or os.environ.get("SENTRY_RELEASE")
        or "brand-web-static"
    ).strip(),
    "sentryErrorSampleRate": float(
        os.environ.get("ONMU_BRAND_SENTRY_ERROR_SAMPLE_RATE", "1")
    ),
    "sentryTracesSampleRate": float(
        os.environ.get("ONMU_BRAND_SENTRY_TRACES_SAMPLE_RATE")
        or os.environ.get("SENTRY_TRACES_SAMPLE_RATE")
        or "0"
    ),
    "sentrySdkUrl": os.environ.get(
        "ONMU_BRAND_SENTRY_SDK_URL",
        "https://browser.sentry-cdn.com/10.59.0/bundle.min.js",
    ).strip(),
    "downloads": {
        "iosUrl": os.environ.get("ONMU_BRAND_IOS_STORE_URL", "").strip(),
        "androidUrl": os.environ.get("ONMU_BRAND_ANDROID_STORE_URL", "").strip(),
    },
}

with open(target, "w", encoding="utf-8") as handle:
    handle.write("window.ONMU_BRAND_CONFIG = ")
    json.dump(config, handle, ensure_ascii=False)
    handle.write(";\n")
PY

stop_pid_file "$cloudflared_pid_file"
stop_pid_file "$http_pid_file"

nohup bash -c 'cd "$1" && exec python3 -m http.server "$2" --bind "$3"' \
  _ "$deploy_dir" "$port" "$host" >"$http_log" 2>&1 &
echo "$!" >"$http_pid_file"

for _ in {1..30}; do
  if curl -fsS "$local_url/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

if ! curl -fsS "$local_url/" >/dev/null 2>&1; then
  echo "Brand web local server did not become ready: $local_url" >&2
  tail -n 20 "$http_log" >&2 || true
  stop_pid_file "$http_pid_file"
  exit 1
fi

if [[ "${ONMU_BRAND_QUICK_TUNNEL:-false}" != "true" ]] && ! has_cloudflared_origin_cert; then
  echo "Cloudflare origin certificate was not found." >&2
  echo "Run 'cloudflared tunnel login' with the ONMU Cloudflare account or set TUNNEL_ORIGIN_CERT, then rerun this script." >&2
  echo "Local brand web server is ready at $local_url; stopping it because public tunnel cannot start." >&2
  stop_pid_file "$http_pid_file"
  exit 2
fi

if [[ "${ONMU_BRAND_ROUTE_DNS:-false}" == "true" ]]; then
  cloudflared tunnel route dns "$tunnel_name" "$domain"
  cloudflared tunnel route dns "$tunnel_name" "www.$domain"
fi

if [[ "${ONMU_BRAND_QUICK_TUNNEL:-false}" == "true" ]]; then
  nohup cloudflared --config "$config_file" tunnel --url "$local_url" >"$cloudflared_log" 2>&1 &
else
  nohup cloudflared --config "$config_file" tunnel run "$tunnel_name" >"$cloudflared_log" 2>&1 &
fi
echo "$!" >"$cloudflared_pid_file"

sleep 5
if ! kill -0 "$(cat "$cloudflared_pid_file")" >/dev/null 2>&1; then
  echo "cloudflared exited before the tunnel became ready." >&2
  tail -n 40 "$cloudflared_log" >&2 || true
  stop_pid_file "$http_pid_file"
  rm -f "$cloudflared_pid_file"
  exit 1
fi

echo "Brand web local server: $local_url"
if [[ "${ONMU_BRAND_QUICK_TUNNEL:-false}" == "true" ]]; then
  echo "Cloudflare quick tunnel started. Check $cloudflared_log for the temporary URL."
else
  echo "Cloudflare tunnel '$tunnel_name' started for https://$domain/"
fi
echo "HTTP log: $http_log"
echo "cloudflared log: $cloudflared_log"
