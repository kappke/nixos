import base64
import json
import os
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

USAGE_URL = "https://chatgpt.com/backend-api/wham/usage"
TOKEN_URL = "https://auth.openai.com/oauth/token"
OAUTH_CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann"
USER_AGENT = "quickshell-chatgpt-usage/1.0"


def read_token_file(path):
    try:
        token = Path(path).expanduser().read_text(encoding="utf-8").strip()
    except (OSError, UnicodeError):
        return ""
    return token.removeprefix("Bearer ").strip()


def read_auth_file(path):
    try:
        auth = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, ValueError):
        return {}
    return auth if isinstance(auth, dict) else {}


def auth_tokens(auth):
    tokens = auth.get("tokens", {})
    return tokens if isinstance(tokens, dict) else {}


def credentials():
    token = os.environ.get("CHATGPT_ACCESS_TOKEN", "").strip()
    account_id = os.environ.get("CHATGPT_ACCOUNT_ID", "").strip()

    if token:
        return token, account_id, None, None, ""

    token = read_token_file(
        os.environ.get("CHATGPT_ACCESS_TOKEN_FILE", "~/.config/chatgpt/access-token")
    )
    if token:
        return token, account_id, None, None, ""

    configured_auth_path = os.environ.get("CHATGPT_AUTH_FILE")
    if configured_auth_path:
        auth_path = Path(configured_auth_path).expanduser()
        auth = read_auth_file(auth_path)
        tokens = auth_tokens(auth)
        token = str(tokens.get("access_token") or "").strip()
        if not account_id:
            account_id = str(tokens.get("account_id") or "").strip()
        return token, account_id, auth_path, auth, "codex"

    opencode_path = Path(
        os.environ.get("CHATGPT_OPENCODE_AUTH_FILE", "~/.local/share/opencode/auth.json")
    ).expanduser()
    opencode_auth = read_auth_file(opencode_path)
    opencode = opencode_auth.get("openai", {})
    if isinstance(opencode, dict):
        token = str(opencode.get("access") or "").strip()
        if token:
            if not account_id:
                account_id = str(opencode.get("accountId") or "").strip()
            return token, account_id, opencode_path, opencode_auth, "opencode"

    auth_path = Path(os.environ.get("CHATGPT_AUTH_FILE", "~/.codex/auth.json")).expanduser()
    auth = read_auth_file(auth_path)
    tokens = auth_tokens(auth)
    token = str(tokens.get("access_token") or "").strip()
    if not account_id:
        account_id = str(tokens.get("account_id") or "").strip()
    return token, account_id, auth_path, auth, "codex"


def token_expired(token):
    parts = token.split(".")
    if len(parts) != 3:
        return False
    try:
        payload = json.loads(
            base64.urlsafe_b64decode(parts[1] + "=" * (-len(parts[1]) % 4))
        )
        if not isinstance(payload, dict):
            return False
        expires_at = float(payload.get("exp"))
    except (AttributeError, TypeError, ValueError, UnicodeError, json.JSONDecodeError):
        return False
    return expires_at <= time.time() + 60


def save_auth_file(path, auth):
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_path = tempfile.mkstemp(
        prefix=f".{path.name}.", dir=path.parent
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as output:
            os.chmod(temporary_path, 0o600)
            json.dump(auth, output, indent=2)
            output.write("\n")
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary_path, path)
    except Exception:
        try:
            os.unlink(temporary_path)
        except OSError:
            pass
        raise


def refresh_credentials(auth_path, auth, auth_format):
    if auth_format == "opencode":
        tokens = auth.get("openai", {})
        refresh_token = str(tokens.get("refresh") or "").strip()
    else:
        tokens = auth_tokens(auth)
        refresh_token = str(tokens.get("refresh_token") or "").strip()
    if not refresh_token:
        raise RuntimeError(
            "ChatGPT access token expired and no refresh token was found. Log in again."
        )

    request = urllib.request.Request(
        os.environ.get("CHATGPT_TOKEN_URL", TOKEN_URL),
        data=json.dumps(
            {
                "client_id": os.environ.get("CHATGPT_OAUTH_CLIENT_ID", OAUTH_CLIENT_ID),
                "grant_type": "refresh_token",
                "refresh_token": refresh_token,
            }
        ).encode("utf-8"),
        headers={
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": USER_AGENT,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            refreshed = json.loads(response.read(1 << 20).decode("utf-8"))
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"ChatGPT token refresh failed (HTTP {error.code})") from error

    if not isinstance(refreshed, dict):
        raise TypeError("ChatGPT token refresh returned invalid data")
    access_token = str(refreshed.get("access_token") or "").strip()
    if not access_token:
        raise RuntimeError("ChatGPT token refresh returned no access token")

    if auth_format == "opencode":
        tokens["access"] = access_token
        if refreshed.get("refresh_token"):
            tokens["refresh"] = refreshed["refresh_token"]
        if refreshed.get("expires_in") is not None:
            try:
                tokens["expires"] = int(
                    (time.time() + float(refreshed["expires_in"])) * 1000
                )
            except (TypeError, ValueError):
                pass
        auth["openai"] = tokens
        account_id = str(tokens.get("accountId") or "").strip()
    else:
        tokens["access_token"] = access_token
        if refreshed.get("refresh_token"):
            tokens["refresh_token"] = refreshed["refresh_token"]
        if refreshed.get("id_token"):
            tokens["id_token"] = refreshed["id_token"]
        auth["tokens"] = tokens
        account_id = str(tokens.get("account_id") or "").strip()
    try:
        save_auth_file(auth_path, auth)
    except OSError as error:
        raise RuntimeError(f"Could not save refreshed ChatGPT credentials: {error}") from error

    return access_token, account_id


def auth_token_expired(token, auth, auth_format):
    if auth_format == "opencode":
        try:
            expires_at = float(auth["openai"]["expires"])
        except (KeyError, TypeError, ValueError):
            return token_expired(token)
        return expires_at <= time.time() * 1000 + 60000
    return token_expired(token)


def request_usage(token, account_id):
    headers = {
        "Accept": "application/json",
        "Authorization": f"Bearer {token}",
        "User-Agent": USER_AGENT,
    }
    if account_id:
        headers["ChatGPT-Account-Id"] = account_id

    request = urllib.request.Request(
        os.environ.get("CHATGPT_USAGE_URL", USAGE_URL), headers=headers
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        payload = json.loads(response.read(1 << 20).decode("utf-8"))
    if not isinstance(payload, dict):
        raise TypeError("ChatGPT returned an invalid usage response")
    return payload


def fetch_usage():
    token, account_id, auth_path, auth, auth_format = credentials()
    refreshed = False
    if auth_path and (not token or auth_token_expired(token, auth, auth_format)):
        token, account_id = refresh_credentials(auth_path, auth, auth_format)
        refreshed = True
    if not token:
        raise RuntimeError(
            "No ChatGPT access token found. Log in with OpenCode/Codex or set CHATGPT_ACCESS_TOKEN."
        )

    try:
        return request_usage(token, account_id)
    except urllib.error.HTTPError as error:
        if error.code != 401 or not auth_path or not auth or refreshed:
            raise
        token, account_id = refresh_credentials(auth_path, auth, auth_format)
        return request_usage(token, account_id)


def main():
    try:
        print(json.dumps(fetch_usage(), separators=(",", ":")))
    except urllib.error.HTTPError as error:
        print(f"ChatGPT usage request failed (HTTP {error.code})", file=sys.stderr)
        return 1
    except (OSError, TypeError, ValueError, RuntimeError, urllib.error.URLError) as error:
        print(f"ChatGPT usage request failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
