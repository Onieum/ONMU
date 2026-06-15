#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

exec python3 "$repo_root/scripts/new-flutter-access-jwt.py" \
  --oauth-only \
  --include-provider-oauth \
  "$@"
