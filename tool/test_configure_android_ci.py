from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import configure_android_ci


class ConfigureAndroidCiTest(unittest.TestCase):
    def test_windows_keystore_path_uses_forward_slashes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            key_properties = Path(directory) / "key.properties"
            environment = {
                "CM_KEYSTORE_PATH": r"C:\Codemagic\elliott-vision.jks",
                "CM_KEYSTORE_PASSWORD": "store-password",
                "CM_KEY_ALIAS": "upload",
                "CM_KEY_PASSWORD": "key-password",
            }
            with (
                patch.object(
                    configure_android_ci,
                    "KEY_PROPERTIES",
                    key_properties,
                ),
                patch.dict(os.environ, environment, clear=False),
            ):
                self.assertTrue(configure_android_ci.write_key_properties())

            self.assertIn(
                "storeFile=C:/Codemagic/elliott-vision.jks",
                key_properties.read_text(encoding="utf-8"),
            )

    def test_incomplete_signing_environment_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            key_properties = Path(directory) / "key.properties"
            environment = {
                "CM_KEYSTORE_PATH": "/tmp/elliott-vision.jks",
                "CM_KEYSTORE_PASSWORD": "store-password",
                "CM_KEY_ALIAS": "",
                "CM_KEY_PASSWORD": "",
            }
            with (
                patch.object(
                    configure_android_ci,
                    "KEY_PROPERTIES",
                    key_properties,
                ),
                patch.dict(os.environ, environment, clear=False),
            ):
                with self.assertRaisesRegex(
                    RuntimeError,
                    "CM_KEY_ALIAS, CM_KEY_PASSWORD",
                ):
                    configure_android_ci.write_key_properties()


if __name__ == "__main__":
    unittest.main()
