"""Developer ID signing, notarization, and verification. Never publishes artifacts."""

import json
import os
from pathlib import Path
import subprocess

from common import SPARKLE_ACCOUNT, TEAM, plist, run, sparkle_tool

MACHO_MAGIC = {b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe", b"\xfe\xed\xfa\xcf",
               b"\xfe\xed\xfa\xce", b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca"}


def identity():
    name = os.environ.get("RATIONS_SIGNING_IDENTITY", f"Developer ID Application: Raw Context LLC ({TEAM})")
    identities = run("security", "find-identity", "-v", "-p", "codesigning", capture=True)
    if not name.startswith("Developer ID Application:") or f"({TEAM})" not in name or f'"{name}"' not in identities:
        raise RuntimeError(f"Install a valid Developer ID Application identity for Raw Context ({TEAM}).")
    return name


def notary_profile():
    return os.environ.get("RATIONS_NOTARY_PROFILE", "Rations")


def preflight(app):
    identity()
    run("xcrun", "notarytool", "history", "--keychain-profile", notary_profile(),
        "--output-format", "json", capture=True)
    public_key = run(sparkle_tool("generate_keys"), "--account", SPARKLE_ACCOUNT, "-p", capture=True)
    expected = plist(app / "Contents" / "Info.plist")["SUPublicEDKey"]
    if public_key != expected:
        raise RuntimeError("The Sparkle signing key does not match the public key embedded in this app.")


def code_objects(app):
    objects = []
    for path in app.rglob("*"):
        if path.is_symlink():
            continue
        if path.is_dir() and path.suffix in (".app", ".xpc", ".framework"):
            objects.append(path)
        elif path.is_file():
            with path.open("rb") as stream:
                if stream.read(4) in MACHO_MAGIC:
                    objects.append(path)
    return sorted(objects, key=lambda path: (-len(path.parts), str(path))) + [app]


def sign(app):
    name = identity()
    print("Signing app and embedded Sparkle components…", flush=True)
    for path in code_objects(app):
        run("codesign", "--force", "--sign", name, "--options", "runtime", "--timestamp",
            "--preserve-metadata=entitlements", path)
    verify(app)


def verify(app):
    run("codesign", "--verify", "--deep", "--strict", app)
    result = subprocess.run(["codesign", "-d", "--verbose=4", str(app)],
                            check=True, text=True, capture_output=True)
    description = result.stderr
    required = ["Authority=Developer ID Application:", f"TeamIdentifier={TEAM}", "runtime", "Timestamp="]
    if not all(value in description for value in required):
        raise RuntimeError("The app is not timestamped Developer ID code with hardened runtime.")
    result = subprocess.run(["codesign", "-d", "--entitlements", ":-", str(app)],
                            check=True, capture_output=True)
    if b"com.apple.security.get-task-allow" in result.stdout:
        raise RuntimeError("The release contains a debugger entitlement.")


def notarize(path):
    print(f"Submitting {Path(path).name} to Apple for notarization…", flush=True)
    result = json.loads(run("xcrun", "notarytool", "submit", path,
                            "--keychain-profile", notary_profile(), "--output-format", "json", capture=True))
    receipt = Path(path).with_suffix(".notary.json")
    receipt.write_text(json.dumps(result, indent=2) + "\n")
    print(f"Apple submission {result['id']} is processing…", flush=True)
    result = json.loads(run("xcrun", "notarytool", "wait", result["id"],
                            "--keychain-profile", notary_profile(), "--timeout", "30m",
                            "--output-format", "json", capture=True))
    receipt.write_text(json.dumps(result, indent=2) + "\n")
    if result.get("status") != "Accepted":
        raise RuntimeError(f"Apple did not accept the submission. See {receipt}.")
    return result["id"]


def staple(path):
    run("xcrun", "stapler", "staple", path)
    run("xcrun", "stapler", "validate", path)
