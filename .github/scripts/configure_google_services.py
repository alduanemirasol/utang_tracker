#!/usr/bin/env python3
import base64
import os
import sys
from pathlib import Path


def main():
    b64_value = os.environ.get("GOOGLE_SERVICES_JSON_BASE64", "").strip()
    raw_value = os.environ.get("GOOGLE_SERVICES_JSON", "").strip()
    output_path = Path("android/app/google-services.json")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if b64_value:
        try:
            decoded = base64.b64decode(b64_value, validate=True)
        except Exception:
            decoded = base64.b64decode(b64_value)
        try:
            decoded_text = decoded.decode("utf-8")
            if not decoded_text.strip().startswith("{"):
                raise ValueError("Decoded content is not JSON")
        except Exception as e:
            print(f"GOOGLE_SERVICES_JSON_BASE64 is not valid base64-encoded JSON: {e}")
            sys.exit(1)
        output_path.write_bytes(decoded)
        print(f"Wrote {output_path} from GOOGLE_SERVICES_JSON_BASE64.")
        return
    if raw_value:
        if not raw_value.strip().startswith("{"):
            print("GOOGLE_SERVICES_JSON is set but does not look like JSON (must start with '{').")
            sys.exit(1)
        output_path.write_text(raw_value, encoding="utf-8", newline="\n")
        print(f"Wrote {output_path} from GOOGLE_SERVICES_JSON.")
        return
    print(
        "Missing Google Services credential: set GOOGLE_SERVICES_JSON_BASE64 "
        "(base64 of android/app/google-services.json) or GOOGLE_SERVICES_JSON "
        "(raw JSON) as a GitHub Secret. Release build cannot continue without "
        "android/app/google-services.json. Generate with: "
        "base64 -w 0 android/app/google-services.json (Linux/macOS) or "
        "[Convert]::ToBase64String([IO.File]::ReadAllBytes('android\\app\\google-services.json')) "
        "in PowerShell (Windows)."
    )
    sys.exit(1)


if __name__ == "__main__":
    main()
