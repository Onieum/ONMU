#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

web_root="$repo_root/apps/mobile-flutter/build/web"
port="5173"
bind_host="127.0.0.1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --web-root)
      web_root="$2"
      shift 2
      ;;
    --port)
      port="$2"
      shift 2
      ;;
    --bind-host)
      bind_host="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'USAGE'
Usage: scripts/macos/serve-flutter-web-spa.sh [options]

Options:
  --web-root <path>   Flutter web build directory. Defaults to apps/mobile-flutter/build/web.
  --port <port>       Local port. Defaults to 5173.
  --bind-host <host>  Bind host. Defaults to 127.0.0.1.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

if [[ ! -f "$web_root/index.html" ]]; then
  echo "index.html not found under WebRoot: $web_root" >&2
  echo "Run: cd apps/mobile-flutter && flutter build web --dart-define-from-file=.dart_tool/onmu-dev-api.defines.json" >&2
  exit 1
fi

python3 -u - "$web_root" "$bind_host" "$port" <<'PY'
from __future__ import annotations

import mimetypes
import os
import posixpath
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit

web_root = Path(sys.argv[1]).resolve()
bind_host = sys.argv[2]
port = int(sys.argv[3])
index_path = web_root / "index.html"

mimetypes.add_type("application/javascript; charset=utf-8", ".js")
mimetypes.add_type("application/javascript; charset=utf-8", ".mjs")
mimetypes.add_type("application/wasm", ".wasm")
mimetypes.add_type("application/json; charset=utf-8", ".json")


class SpaFallbackHandler(SimpleHTTPRequestHandler):
    def log_message(self, format: str, *args: object) -> None:
        sys.stdout.write("%s - - [%s] %s\n" % (self.client_address[0], self.log_date_time_string(), format % args))
        sys.stdout.flush()

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def translate_path(self, path: str) -> str:
        request_path = unquote(urlsplit(path).path)
        normalized = posixpath.normpath(request_path)
        parts = [part for part in normalized.split("/") if part and part not in (".", "..")]
        candidate = web_root.joinpath(*parts).resolve()

        if not str(candidate).startswith(str(web_root)):
            return str(index_path)
        if candidate.is_dir():
            index = candidate / "index.html"
            if index.is_file():
                return str(index)
        if candidate.is_file():
            return str(candidate)

        _, extension = os.path.splitext(request_path)
        if not extension:
            return str(index_path)
        return str(candidate)


server = ThreadingHTTPServer((bind_host, port), SpaFallbackHandler)
print(f"Serving Flutter Web SPA from {web_root}")
print(f"Listening on http://{bind_host}:{port}/")
print("SPA fallback: extensionless missing routes return index.html")
try:
    server.serve_forever()
finally:
    server.server_close()
PY
