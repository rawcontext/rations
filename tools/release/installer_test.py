"""Exercise installer metadata on an isolated disk image with synthetic app data."""

from pathlib import Path
import tempfile
import unittest

import artifacts
from common import run


class InstallerTests(unittest.TestCase):
    def test_downloaded_image_retains_volume_icon_and_install_shortcut(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            app = root / "Fixture.app"
            resources = app / "Contents" / "Resources"
            resources.mkdir(parents=True)
            icon = b"icns\x00\x00\x00\x08"
            (resources / "AppIcon.icns").write_bytes(icon)
            image = root / "installer.dmg"
            artifacts.disk_image(app, image)
            download = root / "download.dmg"
            download.write_bytes(image.read_bytes())
            mount = root / "mounted"
            run("hdiutil", "attach", "-readonly", "-nobrowse", "-mountpoint", mount, download)
            try:
                self.assertEqual((mount / ".VolumeIcon.icns").read_bytes(), icon)
                metadata = run("xattr", "-px", "com.apple.FinderInfo", mount, capture=True)
                flags = int.from_bytes(bytes.fromhex(metadata)[8:10], "big")
                self.assertTrue(flags & 0x400)
                self.assertEqual((mount / "Applications").readlink(), Path("/Applications"))
                self.assertEqual((mount / "Rations.app/Contents/Resources/AppIcon.icns").read_bytes(), icon)
            finally:
                run("hdiutil", "detach", mount)
