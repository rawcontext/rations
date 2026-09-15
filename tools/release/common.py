"""Shared paths and process execution for the local macOS release workflow."""

import hashlib
import os
from pathlib import Path
import plistlib
import subprocess

ROOT = Path(__file__).resolve().parents[2]
REPOSITORY = "rawcontext/rations"
TEAM = "U65DCW9TAK"
SPARKLE_ACCOUNT = "com.rawcontext.rations"
FEED_URL = f"https://github.com/{REPOSITORY}/releases/latest/download/appcast.xml"


def run(*arguments, capture=False, **options):
    command = [str(argument) for argument in arguments]
    environment = options.pop("env", os.environ.copy())
    environment.setdefault("DEVELOPER_DIR", "/Applications/Xcode-beta.app/Contents/Developer")
    result = subprocess.run(command, cwd=ROOT, check=True, text=True,
                            stdout=subprocess.PIPE if capture else None, env=environment, **options)
    return result.stdout.strip() if capture else None


def plist(path):
    with Path(path).open("rb") as stream:
        return plistlib.load(stream)


def digest(path):
    checksum = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(chunk)
    return checksum.hexdigest()


def sparkle_tool(name):
    output_base = Path(run("bazel", "info", "output_base", capture=True))
    candidates = list((output_base / "external").glob("*sparkle*/bin/" + name))
    if len(candidates) != 1:
        raise RuntimeError("Build the distribution target to resolve the pinned Sparkle tools.")
    return candidates[0]
