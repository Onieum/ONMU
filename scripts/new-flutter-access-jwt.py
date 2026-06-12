#!/usr/bin/env python3
import argparse
import base64
import hashlib
import hmac
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional, Tuple


def base64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def default_api_base_url(environment: str) -> str:
    if environment == "integration":
        return "https://int-api.onmu.cloud"
    return "https://dev-api.onmu.cloud"


def default_output_path(environment: str) -> Path:
    file_name = (
        "onmu-integration-api.defines.json"
        if environment == "integration"
        else "onmu-dev-api.defines.json"
    )
    return repo_root() / "apps" / "mobile-flutter" / ".dart_tool" / file_name


def key_vault_secret_name(environment: str) -> str:
    prefix = "int" if environment == "integration" else "dev"
    return f"{prefix}-access-token-secret"


def kakao_rest_api_key_secret_name(environment: str) -> str:
    prefix = "int" if environment == "integration" else "dev"
    return f"{prefix}-kakao-rest-api-key"


def default_kakao_oauth_redirect_uri(api_base_url: str) -> str:
    return f"{api_base_url.rstrip('/')}/api/v1/auth/oauth/kakao/callback"


def azure_cli_executable() -> str:
    candidates = ["az.cmd", "az.exe", "az"] if os.name == "nt" else ["az"]
    for candidate in candidates:
        if shutil.which(candidate):
            return candidate
    return "az"


def read_secret_from_key_vault(vault_name: str, secret_name: str) -> str:
    command = [
        azure_cli_executable(),
        "keyvault",
        "secret",
        "show",
        "--vault-name",
        vault_name,
        "--name",
        secret_name,
        "--query",
        "value",
        "-o",
        "tsv",
    ]
    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
    except FileNotFoundError as exc:
        raise RuntimeError(
            "Azure CLI 'az' was not found. Set ONMU_ACCESS_TOKEN_SECRET or install Azure CLI."
        ) from exc
    except subprocess.CalledProcessError as exc:
        message = (exc.stderr or "").strip()
        if message:
            raise RuntimeError(f"Failed to read {secret_name} from Key Vault: {message}") from exc
        raise RuntimeError(f"Failed to read {secret_name} from Key Vault.") from exc

    secret = result.stdout.strip()
    if not secret:
        raise RuntimeError(f"Key Vault secret {secret_name} was empty or unavailable.")
    return secret


def resolve_secret(environment: str, vault_name: Optional[str]) -> str:
    env_secret = os.environ.get("ONMU_ACCESS_TOKEN_SECRET")
    if env_secret:
        return env_secret

    secret_name = key_vault_secret_name(environment)
    if not vault_name:
        raise RuntimeError(
            "ONMU_ACCESS_TOKEN_SECRET is not set. Set it for local testing or pass "
            f"--vault-name to load {secret_name} from Key Vault."
        )
    return read_secret_from_key_vault(vault_name, secret_name)


def resolve_kakao_rest_api_key(environment: str, vault_name: Optional[str]) -> str:
    env_value = os.environ.get("KAKAO_REST_API_KEY") or os.environ.get("KAKAO_OAUTH_CLIENT_ID")
    if env_value:
        return env_value.strip()

    secret_name = kakao_rest_api_key_secret_name(environment)
    if not vault_name:
        raise RuntimeError(
            "KAKAO_REST_API_KEY is not set. Set it for local testing or pass "
            f"--vault-name to load {secret_name} from Key Vault."
        )
    return read_secret_from_key_vault(vault_name, secret_name)


def build_jwt(
    secret: str,
    issuer: str,
    audience: str,
    subject: str,
    expires_in_minutes: int,
) -> Tuple[str, datetime]:
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=expires_in_minutes)
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {
        "iss": issuer,
        "aud": audience,
        "sub": subject,
        "typ": "access",
        "iat": int(now.timestamp()),
        "exp": int(expires_at.timestamp()),
    }

    header_part = base64url(json.dumps(header, separators=(",", ":")).encode("utf-8"))
    payload_part = base64url(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signing_input = f"{header_part}.{payload_part}"
    signature = hmac.new(
        secret.encode("utf-8"),
        signing_input.encode("ascii"),
        hashlib.sha256,
    ).digest()
    return f"{signing_input}.{base64url(signature)}", expires_at


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate a local Flutter dart-define file with an ONMU access JWT."
    )
    parser.add_argument("--environment", choices=["dev", "integration"], default="dev")
    parser.add_argument("--vault-name", default=os.environ.get("AZURE_KEY_VAULT_NAME"))
    parser.add_argument("--user-public-id", default="user-me")
    parser.add_argument("--expires-in-minutes", type=int, default=120)
    parser.add_argument("--issuer", default=os.environ.get("ONMU_AUTH_ISSUER") or "onmu-api")
    parser.add_argument("--audience", default=os.environ.get("ONMU_AUTH_AUDIENCE") or "onmu-mobile")
    parser.add_argument("--api-base-url")
    parser.add_argument("--output-path")
    parser.add_argument(
        "--include-kakao-oauth",
        action="store_true",
        help="Include Kakao browser OAuth public client id and redirect URI in the local dart-define file.",
    )
    parser.add_argument("--kakao-oauth-redirect-uri")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.expires_in_minutes < 5 or args.expires_in_minutes > 1440:
        print("ExpiresInMinutes must be between 5 and 1440.", file=sys.stderr)
        return 2

    subject = args.user_public_id.strip()
    if not subject:
        print("UserPublicId is required.", file=sys.stderr)
        return 2

    try:
        secret = resolve_secret(args.environment, args.vault_name)
        token, expires_at = build_jwt(
            secret=secret,
            issuer=args.issuer,
            audience=args.audience,
            subject=subject,
            expires_in_minutes=args.expires_in_minutes,
        )
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    api_base_url = args.api_base_url or default_api_base_url(args.environment)
    output_path = Path(args.output_path).expanduser() if args.output_path else default_output_path(args.environment)
    output_path = output_path.resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    defines = {
        "ONMU_API_BASE_URL": api_base_url,
        "ONMU_API_ACCESS_JWT": token,
        "ONMU_DEV_ACCESS_TOKEN": token,
    }

    if args.include_kakao_oauth:
        try:
            kakao_rest_api_key = resolve_kakao_rest_api_key(args.environment, args.vault_name)
        except RuntimeError as exc:
            print(str(exc), file=sys.stderr)
            return 1
        if not kakao_rest_api_key:
            print("KAKAO_REST_API_KEY could not be loaded.", file=sys.stderr)
            return 1
        defines["KAKAO_REST_API_KEY"] = kakao_rest_api_key
        defines["KAKAO_OAUTH_REDIRECT_URI"] = (
            args.kakao_oauth_redirect_uri or default_kakao_oauth_redirect_uri(api_base_url)
        )

    output_path.write_text(
        json.dumps(defines, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"Wrote Flutter dart-define file: {output_path}")
    print(f"JWT subject: {subject}")
    print(f"JWT expires at UTC: {expires_at.strftime('%Y-%m-%dT%H:%M:%SZ')}")
    print("Token value is stored only in the local ignored dart-define file and is not printed.")
    if args.include_kakao_oauth:
        print("Included Kakao OAuth dart-define keys without printing their values.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
