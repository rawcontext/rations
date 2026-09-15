"""Synthetic release validation; never reads real signing credentials or endpoints."""

from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import artifacts
from common import FEED_URL
import signing


class ArtifactTests(unittest.TestCase):
    def test_development_and_unconfigured_bundles_cannot_ship(self):
        info = {"CFBundleIdentifier": "com.rawcontext.rations.dev"}
        with self.assertRaises(RuntimeError):
            artifacts.validate_bundle(info)
        info["CFBundleIdentifier"] = "com.rawcontext.rations"
        with self.assertRaises(RuntimeError):
            artifacts.validate_bundle(info)

    def test_production_bundle_requires_numeric_versions(self):
        info = {"CFBundleIdentifier": "com.rawcontext.rations", "SUFeedURL": FEED_URL,
                "SUPublicEDKey": "synthetic", "CFBundleShortVersionString": "0.1.0",
                "CFBundleVersion": "1"}
        artifacts.validate_bundle(info)
        info["CFBundleVersion"] = "../invalid"
        with self.assertRaises(RuntimeError):
            artifacts.validate_bundle(info)

    def test_nested_helpers_are_signed_before_the_app(self):
        with tempfile.TemporaryDirectory() as directory:
            app = Path(directory) / "Rations.app"
            helper = app / "Contents/Frameworks/Sparkle.framework/Updater.app"
            executable = helper / "Contents/MacOS/Updater"
            executable.parent.mkdir(parents=True)
            executable.write_bytes(b"\xcf\xfa\xed\xfe" + b"fixture")
            (helper / "alias").symlink_to(executable)
            (helper / "notice.txt").write_text("Not executable")
            order = signing.code_objects(app)
            self.assertLess(order.index(executable), order.index(helper))
            self.assertEqual(order[-1], app)
            self.assertNotIn(helper / "alias", order)
            self.assertNotIn(helper / "notice.txt", order)

    @patch("artifacts.sparkle_tool", return_value="fixture-sign-update")
    @patch("artifacts.run")
    def test_appcast_must_match_archive_and_release_url(self, run, _tool):
        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "Rations-0.1.0.dmg"
            image.write_bytes(b"synthetic image")
            feed = Path(directory) / "appcast.xml"
            url = "https://github.com/rawcontext/rations/releases/download/v0.1.0/" + image.name
            template = ('<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">'
                        '<channel><item><enclosure url="{}" length="{}" sparkle:edSignature="fixture"/>'
                        '</item></channel></rss>')
            feed.write_text(template.format(url, image.stat().st_size))
            artifacts.validate_appcast(feed, image, "0.1.0")
            self.assertEqual(run.call_count, 2)
            for bad_url, bad_size in [("https://example.invalid/untrusted.dmg", 15), (url, 100)]:
                feed.write_text(template.format(bad_url, bad_size))
                with self.assertRaises(RuntimeError):
                    artifacts.validate_appcast(feed, image, "0.1.0")

    @patch("signing.run", return_value='1) abc "Apple Development: Fixture (U65DCW9TAK)"')
    def test_development_certificate_cannot_sign_a_release(self, _run):
        with patch.dict("os.environ", {"RATIONS_SIGNING_IDENTITY": "Apple Development: Fixture (U65DCW9TAK)"}):
            with self.assertRaises(RuntimeError):
                signing.identity()


if __name__ == "__main__":
    unittest.main()
