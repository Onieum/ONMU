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


def default_oauth_output_path(environment: str) -> Path:
    file_name = (
        "onmu-integration-oauth.defines.json"
        if environment == "integration"
        else "onmu-dev-oauth.defines.json"
    )
    return repo_root() / "apps" / "mobile-flutter" / ".dart_tool" / file_name


def key_vault_secret_name(environment: str) -> str:
    prefix = "int" if environment == "integration" else "dev"
    return f"{prefix}-access-token-secret"


def kakao_rest_api_key_secret_name(environment: str) -> str:
    prefix = "int" if environment == "integration" else "dev"
    return f"{prefix}-kakao-rest-api-key"


def naver_oauth_client_id_secret_name(environment: str) -> str:
    prefix = "int" if environment == "integration" else "dev"
    return f"{prefix}-naver-oauth-client-id"


def google_oauth_client_id_secret_name(environment: str) -> str:
    prefix = "int" if environment == "integration" else "dev"
    return f"{prefix}-google-oauth-client-id"


def google_server_client_id_secret_name(environment: str) -> str:
    prefix = "int" if environment == "integration" else "dev"
    return f"{prefix}-google-server-client-id"


def default_kakao_oauth_redirect_uri(api_base_url: str) -> str:
    return f"{api_base_url.rstrip('/')}/api/v1/auth/oauth/kakao/callback"


def default_naver_oauth_redirect_uri(api_base_url: str) -> str:
    return f"{api_base_url.rstrip('/')}/api/v1/auth/oauth/naver/callback"


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
            "Azure CLI 'az' was not found. Set the required environment variable or install Azure CLI."
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


def resolve_naver_oauth_client_id(environment: str, vault_name: Optional[str]) -> str:
    env_value = os.environ.get("NAVER_OAUTH_CLIENT_ID")
    if env_value:
        return env_value.strip()

    secret_name = naver_oauth_client_id_secret_name(environment)
    if not vault_name:
        raise RuntimeError(
            "NAVER_OAUTH_CLIENT_ID is not set. Set it for local testing or pass "
            f"--vault-name to load {secret_name} from Key Vault."
        )
    return read_secret_from_key_vault(vault_name, secret_name)


def resolve_google_oauth_client_id(environment: str, vault_name: Optional[str]) -> str:
    env_value = os.environ.get("GOOGLE_CLIENT_ID") or os.environ.get("GOOGLE_OAUTH_CLIENT_ID")
    if env_value:
        return env_value.strip()

    secret_name = google_oauth_client_id_secret_name(environment)
    if not vault_name:
        raise RuntimeError(
            "GOOGLE_CLIENT_ID or GOOGLE_OAUTH_CLIENT_ID is not set. Set it for local testing or pass "
            f"--vault-name to load {secret_name} from Key Vault."
        )
    return read_secret_from_key_vault(vault_name, secret_name)


def resolve_google_server_client_id(environment: str, vault_name: Optional[str]) -> str:
    env_value = os.environ.get("GOOGLE_SERVER_CLIENT_ID")
    if env_value:
        return env_value.strip()

    secret_name = google_server_client_id_secret_name(environment)
    if not vault_name:
        raise RuntimeError(
            "GOOGLE_SERVER_CLIENT_ID is not set. Set it for local testing or pass "
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
        description="Generate a local Flutter dart-define file with ONMU API or public OAuth settings."
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
        "--oauth-only",
        action="store_true",
        help="Write only public OAuth dart-defines and skip ONMU access JWT generation.",
    )
    parser.add_argument(
        "--include-provider-oauth",
        action="store_true",
        help="Include all public provider OAuth dart-defines supported by the Flutter app.",
    )
    parser.add_argument(
        "--include-kakao-oauth",
        action="store_true",
        help="Include Kakao browser OAuth public client id and redirect URI in the local dart-define file.",
    )
    parser.add_argument(
        "--include-naver-oauth",
        action="store_true",
        help="Include Naver browser OAuth public client id and redirect URI in the local dart-define file.",
    )
    parser.add_argument(
        "--include-google-oauth",
        action="store_true",
        help="Include Google OAuth public client id values in the local dart-define file.",
    )
    parser.add_argument("--kakao-oauth-redirect-uri")
    parser.add_argument("--naver-oauth-redirect-uri")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.expires_in_minutes < 5 or args.expires_in_minutes > 1440:
        print("ExpiresInMinutes must be between 5 and 1440.", file=sys.stderr)
        return 2

    api_base_url = args.api_base_url or default_api_base_url(args.environment)
    default_path = (
        default_oauth_output_path(args.environment)
        if args.oauth_only
        else default_output_path(args.environment)
    )
    output_path = Path(args.output_path).expanduser() if args.output_path else default_path
    output_path = output_path.resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    defines = {
        "ONMU_API_BASE_URL": api_base_url,
    }

    token = None
    expires_at = None
    subject = args.user_public_id.strip()
    if not args.oauth_only:
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

        defines["ONMU_API_ACCESS_JWT"] = token
        defines["ONMU_DEV_ACCESS_TOKEN"] = token

    include_kakao_oauth = args.include_kakao_oauth or args.include_provider_oauth
    include_naver_oauth = args.include_naver_oauth or args.include_provider_oauth
    include_google_oauth = args.include_google_oauth or args.include_provider_oauth

    if args.oauth_only and not (include_kakao_oauth or include_naver_oauth or include_google_oauth):
        include_kakao_oauth = True
        include_naver_oauth = True
        include_google_oauth = True

    if include_kakao_oauth:
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

    if include_naver_oauth:
        try:
            naver_oauth_client_id = resolve_naver_oauth_client_id(args.environment, args.vault_name)
        except RuntimeError as exc:
            print(str(exc), file=sys.stderr)
            return 1
        if not naver_oauth_client_id:
            print("NAVER_OAUTH_CLIENT_ID could not be loaded.", file=sys.stderr)
            return 1
        defines["NAVER_OAUTH_CLIENT_ID"] = naver_oauth_client_id
        defines["NAVER_OAUTH_REDIRECT_URI"] = (
            args.naver_oauth_redirect_uri or default_naver_oauth_redirect_uri(api_base_url)
        )

    if include_google_oauth:
        try:
            google_oauth_client_id = resolve_google_oauth_client_id(args.environment, args.vault_name)
            google_server_client_id = resolve_google_server_client_id(args.environment, args.vault_name)
        except RuntimeError as exc:
            print(str(exc), file=sys.stderr)
            return 1
        if not google_oauth_client_id:
            print("GOOGLE_CLIENT_ID could not be loaded.", file=sys.stderr)
            return 1
        if not google_server_client_id:
            print("GOOGLE_SERVER_CLIENT_ID could not be loaded.", file=sys.stderr)
            return 1
        defines["GOOGLE_CLIENT_ID"] = google_oauth_client_id
        defines["GOOGLE_SERVER_CLIENT_ID"] = google_server_client_id

    output_path.write_text(
        json.dumps(defines, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"Wrote Flutter dart-define file: {output_path}")
    if not args.oauth_only:
        print(f"JWT subject: {subject}")
        print(f"JWT expires at UTC: {expires_at.strftime('%Y-%m-%dT%H:%M:%SZ')}")
        print("Token value is stored only in the local ignored dart-define file and is not printed.")
    else:
        print("OAuth-only define file was written without an ONMU access JWT.")
    if include_kakao_oauth:
        print("Included Kakao OAuth dart-define keys without printing their values.")
    if include_naver_oauth:
        print("Included Naver OAuth dart-define keys without printing their values.")
    if include_google_oauth:
        print("Included Google OAuth dart-define keys without printing their values.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
