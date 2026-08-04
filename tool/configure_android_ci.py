#!/usr/bin/env python3
"""Konfiguriert das von Flutter erzeugte Android-Projekt reproduzierbar."""

from __future__ import annotations

import os
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"
GRADLE = ROOT / "android/app/build.gradle.kts"
KEY_PROPERTIES = ROOT / "android/key.properties"
SIGNING_MARKER = "// ELLIOTT_VISION_SIGNING"


def configure_manifest() -> None:
    text = MANIFEST.read_text(encoding="utf-8")
    text = re.sub(
        r'android:label="[^"]*"',
        'android:label="Elliott Vision"',
        text,
        count=1,
    )
    permission = (
        '    <uses-permission android:name="android.permission.INTERNET" />'
    )
    if "android.permission.INTERNET" not in text:
        text = re.sub(r"(<manifest[^>]*>)", rf"\1\n{permission}", text, count=1)
    MANIFEST.write_text(text, encoding="utf-8")


def write_key_properties() -> bool:
    names = (
        "CM_KEYSTORE_PATH",
        "CM_KEYSTORE_PASSWORD",
        "CM_KEY_ALIAS",
        "CM_KEY_PASSWORD",
    )
    values = {name: os.environ.get(name, "") for name in names}
    if not any(values.values()):
        if KEY_PROPERTIES.exists():
            KEY_PROPERTIES.unlink()
        return False
    missing = [name for name, value in values.items() if not value]
    if missing:
        raise RuntimeError(
            "Unvollstaendige Codemagic-Signierung: " + ", ".join(missing)
        )
    KEY_PROPERTIES.write_text(
        "\n".join(
            (
                f"storePassword={values['CM_KEYSTORE_PASSWORD']}",
                f"keyPassword={values['CM_KEY_PASSWORD']}",
                f"keyAlias={values['CM_KEY_ALIAS']}",
                f"storeFile={values['CM_KEYSTORE_PATH']}",
                "",
            )
        ),
        encoding="utf-8",
    )
    return True


def configure_gradle() -> None:
    text = GRADLE.read_text(encoding="utf-8")
    if SIGNING_MARKER in text:
        return
    imports = "import java.io.FileInputStream\nimport java.util.Properties\n\n"
    if "import java.util.Properties" not in text:
        text = imports + text
    properties = f"""
{SIGNING_MARKER}
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {{
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}}

"""
    if "val keystoreProperties = Properties()" not in text:
        text = text.replace("android {", properties + "android {", 1)
    signing = """
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

"""
    if 'create("release")' not in text:
        text, count = re.subn(
            r"(?m)^(\s*)buildTypes\s*\{",
            lambda match: signing + match.group(0),
            text,
            count=1,
        )
        if count != 1:
            raise RuntimeError("buildTypes-Block wurde nicht gefunden")
    old_signing = 'signingConfig = signingConfigs.getByName("debug")'
    new_signing = (
        'signingConfig = if (keystorePropertiesFile.exists()) '
        'signingConfigs.getByName("release") else '
        'signingConfigs.getByName("debug")'
    )
    if old_signing not in text:
        raise RuntimeError("Flutter-Standard-Signaturzeile wurde nicht gefunden")
    text = text.replace(old_signing, new_signing, 1)
    GRADLE.write_text(text, encoding="utf-8")


def main() -> None:
    if not MANIFEST.exists() or not GRADLE.exists():
        raise RuntimeError("Android-Projekt fehlt; zuerst flutter create ausfuehren")
    configure_manifest()
    signed = write_key_properties()
    configure_gradle()
    mode = "Release-Signierung aktiv" if signed else "Debug-Signierung aktiv"
    print(f"Android-Konfiguration abgeschlossen: {mode}.")


if __name__ == "__main__":
    main()
