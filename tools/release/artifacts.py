"""Build and package the Bazel-owned production app."""

from pathlib import Path
import shutil
import tempfile
import xml.etree.ElementTree as ET

from common import FEED_URL, ROOT, SPARKLE_ACCOUNT, digest, plist, run, sparkle_tool
from signing import code_objects


def validate_bundle(info):
    if info.get("CFBundleIdentifier") != "com.rawcontext.rations":
        raise RuntimeError("Refusing to distribute a development bundle.")
    if info.get("SUFeedURL") != FEED_URL or not info.get("SUPublicEDKey"):
        raise RuntimeError("The app has no valid production update configuration.")
    for key in ("CFBundleShortVersionString", "CFBundleVersion"):
        if not str(info.get(key, "")).replace(".", "").isdigit():
            raise RuntimeError(f"Invalid release version: {key}")


def build():
    print("Building the production app for Apple Silicon and Intel…", flush=True)
    target = ["--config=distribution", "//apps/macos:app"]
    run("bazel", "build", *target)
    archive = ROOT / run("bazel", "cquery", *target, "--output=files", capture=True)
    work = ROOT / "dist" / "release-work"
    work.mkdir(parents=True, exist_ok=True)
    app = work / "Rations.app"
    if app.exists():
        shutil.rmtree(app)
    run("ditto", "-x", "-k", archive, work)
    info = plist(app / "Contents" / "Info.plist")
    validate_bundle(info)
    validate_architectures(app)
    run("plutil", "-lint", app / "Contents" / "Resources" / "PrivacyInfo.xcprivacy")
    for notice in ["RationsLicense.txt", "SparkleLicense.txt", "CodexBarAttribution.txt", "IconAttribution.txt"]:
        if not (app / "Contents" / "Resources" / notice).is_file():
            raise RuntimeError(f"The release is missing a license notice: {notice}")
    if (app / "Contents" / "embedded.provisionprofile").exists():
        raise RuntimeError("A development provisioning profile leaked into the distribution app.")
    return app


def validate_architectures(app):
    for path in code_objects(app):
        if path.is_file():
            architectures = set(run("lipo", "-archs", path, capture=True).split())
            if not {"arm64", "x86_64"}.issubset(architectures):
                raise RuntimeError(f"The release contains code without both supported architectures: {path}")


def disk_image(app, output):
    with tempfile.TemporaryDirectory(prefix="rations-dmg-") as temporary:
        payload = Path(temporary)
        run("ditto", app, payload / "Rations.app")
        (payload / "Applications").symlink_to("/Applications")
        run("hdiutil", "create", "-volname", "Rations", "-srcfolder", payload,
            "-fs", "HFS+", "-format", "UDZO", output)


def appcast(output, version):
    notes = ROOT / "releases" / (version + ".md")
    if not notes.is_file():
        raise RuntimeError(f"Missing release notes: {notes}")
    image = output / ("Rations-" + version + ".dmg")
    shutil.copyfile(notes, image.with_suffix(".md"))
    run(sparkle_tool("generate_appcast"), "--account", SPARKLE_ACCOUNT,
        "--download-url-prefix", f"https://github.com/rawcontext/rations/releases/download/v{version}/",
        "--link", "https://rawcontext.com/projects/rations/", "--maximum-deltas", "0",
        "--embed-release-notes", output)
    validate_appcast(output / "appcast.xml", image, version)
    download = output / "Rations.dmg"
    shutil.copyfile(image, download)
    files = [image, download, output / "appcast.xml"]
    (output / "SHA256SUMS").write_text("".join(f"{digest(path)}  {path.name}\n" for path in files))


def validate_appcast(feed, image, version):
    run(sparkle_tool("sign_update"), "--account", SPARKLE_ACCOUNT, "--verify", feed)
    enclosure = ET.parse(feed).find("./channel/item/enclosure")
    namespace = "{http://www.andymatuschak.org/xml-namespaces/sparkle}"
    expected = f"https://github.com/rawcontext/rations/releases/download/v{version}/{image.name}"
    if enclosure is None or enclosure.get("url") != expected:
        raise RuntimeError("The appcast does not point to this release artifact.")
    if enclosure.get("length") != str(image.stat().st_size):
        raise RuntimeError("The appcast archive size does not match.")
    signature = enclosure.get(namespace + "edSignature")
    if not signature:
        raise RuntimeError("The appcast has no update signature.")
    run(sparkle_tool("sign_update"), "--account", SPARKLE_ACCOUNT, "--verify", image, signature)
