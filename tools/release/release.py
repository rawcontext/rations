#!/usr/bin/env python3
"""Prepare, notarize, or publish Rations. Run from any working directory."""

import argparse
import json
import subprocess
import sys

import artifacts
from common import REPOSITORY, ROOT, digest, plist, run
import signing


def clean_commit():
    if run("git", "status", "--porcelain", capture=True):
        raise RuntimeError("Commit the release source before signing or publishing.")
    return run("git", "rev-parse", "HEAD", capture=True)


def release():
    commit = clean_commit()
    run("npm", "run", "check")
    app = artifacts.build()
    signing.preflight(app)
    info = plist(app / "Contents" / "Info.plist")
    version = info["CFBundleShortVersionString"]
    output = ROOT / "dist" / "releases" / version
    output.mkdir(parents=True, exist_ok=False)
    signing.sign(app)
    submission = app.parent / "Rations-notarization.zip"
    run("ditto", "-c", "-k", "--keepParent", app, submission)
    app_notary_id = signing.notarize(submission)
    signing.staple(app)
    image = output / f"Rations-{version}.dmg"
    artifacts.disk_image(app, image)
    run("codesign", "--sign", signing.identity(), "--timestamp", image)
    image_notary_id = signing.notarize(image)
    signing.staple(image)
    run("spctl", "--assess", "--type", "execute", "--verbose=2", app)
    artifacts.appcast(output, version)
    manifest = {"version": version, "build": info["CFBundleVersion"], "commit": commit,
                "dmgSHA256": digest(image), "appNotaryID": app_notary_id, "dmgNotaryID": image_notary_id}
    (output / "release.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Signed, notarized release ready: {output}")


def publish():
    commit = clean_commit()
    info = plist(ROOT / "apps" / "macos" / "Resources" / "Info.plist")
    version = info["CFBundleShortVersionString"]
    output = ROOT / "dist" / "releases" / version
    manifest = json.loads((output / "release.json").read_text())
    image = output / f"Rations-{version}.dmg"
    if manifest["commit"] != commit or manifest["dmgSHA256"] != digest(image):
        raise RuntimeError("Release source or artifact changed after notarization.")
    if digest(output / "Rations.dmg") != manifest["dmgSHA256"]:
        raise RuntimeError("The stable download differs from the verified installer.")
    run("xcrun", "stapler", "validate", image)
    artifacts.validate_appcast(output / "appcast.xml", image, version)
    remote = json.loads(run("gh", "repo", "view", REPOSITORY,
                            "--json", "isPrivate", capture=True))
    if remote["isPrivate"]:
        raise RuntimeError("Public downloads require a public release repository.")
    tag = "v" + version
    run("git", "push", "origin", "HEAD")
    run("git", "tag", "-a", tag, "-m", "Rations " + version)
    run("git", "push", "origin", tag)
    run("gh", "release", "create", tag, image, output / "Rations.dmg", output / "appcast.xml", output / "SHA256SUMS",
        "--repo", REPOSITORY, "--verify-tag", "--title", "Rations " + version,
        "--notes-file", ROOT / "releases" / (version + ".md"))
    verify_download(output, version, manifest)


def verify_download(output, version, manifest):
    directory = output / "download-verification"
    directory.mkdir(exist_ok=True)
    run("gh", "release", "download", "v" + version, "--repo", REPOSITORY,
        "--pattern", "*.dmg", "--dir", directory, "--clobber")
    image = directory / f"Rations-{version}.dmg"
    if digest(image) != manifest["dmgSHA256"]:
        raise RuntimeError("The uploaded installer differs from the verified release.")
    if digest(directory / "Rations.dmg") != manifest["dmgSHA256"]:
        raise RuntimeError("The stable public download does not match the verified release.")
    run("xcrun", "stapler", "validate", image)
    print(f"Published and verified: https://github.com/{REPOSITORY}/releases/tag/v{version}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["prepare", "release", "publish"])
    args = parser.parse_args()
    if args.action == "prepare":
        print(artifacts.build())
    elif args.action == "release":
        release()
    else:
        publish()


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, subprocess.CalledProcessError, FileNotFoundError) as error:
        print(f"Release stopped: {error}", file=sys.stderr)
        sys.exit(1)
