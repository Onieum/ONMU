#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
defines_file="$repo_root/apps/mobile-flutter/.dart_tool/onmu-dev-api.defines.json"

if [[ ! -f "$defines_file" ]]; then
  "$script_dir/new-flutter-access-jwt.sh" --environment dev
fi

cd "$repo_root/apps/mobile-flutter"
exec flutter run \
  -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port 5173 \
  --dart-define-from-file=.dart_tool/onmu-dev-api.defines.json \
  "$@"
