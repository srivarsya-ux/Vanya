#!/usr/bin/env python3
"""
Wires the manually-staged native Android files (android_native_files/) into
the android/ platform folder that `flutter create .` generates, following
android_native_files/SETUP.md steps 1-3 and the "Android App Widgets"
section exactly -- automated so a CI build doesn't need a human to follow
those copy-paste instructions by hand.

Run AFTER `flutter create . --platforms android --org com.oneir --project-name app`
(that combination of --org/--project-name is what makes the generated
applicationId come out as com.oneir.app, matching every `package com.oneir.app`
line in android_native_files/**/*.kt -- see SETUP.md's package-name note).

Idempotent: safe to run more than once (checks for its own marker comment
in AndroidManifest.xml before inserting anything there, and file copies
just overwrite).
"""
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NATIVE = ROOT / "android_native_files"
ANDROID = ROOT / "android"
PKG_DIR = ANDROID / "app" / "src" / "main" / "kotlin" / "com" / "oneir" / "app"
RES = ANDROID / "app" / "src" / "main" / "res"
MANIFEST = ANDROID / "app" / "src" / "main" / "AndroidManifest.xml"

MARKER = "<!-- ONEIR NATIVE ADDITIONS (tool/wire_native.py) -->"

MANIFEST_LEVEL_ADDITIONS = """
    <queries>
        <intent>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent>
    </queries>
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions" />
"""

APPLICATION_LEVEL_ADDITIONS = """
        <service
            android:name=".OneirAccessibilityService"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
            android:exported="false">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/oneir_accessibility_service_config" />
        </service>

        <activity
            android:name=".InterruptionActivity"
            android:exported="false"
            android:excludeFromRecents="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme" />

        <meta-data
            android:name="io.flutter.embedding.android.EnableDartEntrypointArgs"
            android:value="true" />

        <receiver
            android:name=".TodaysFocusWidgetProvider"
            android:exported="false">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/todays_focus_widget_info" />
        </receiver>

        <receiver
            android:name=".QuickFocusWidgetProvider"
            android:exported="false">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/quick_focus_widget_info" />
        </receiver>

        <receiver
            android:name=".VanyaCheckInWidgetProvider"
            android:exported="false">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/vanya_checkin_widget_info" />
        </receiver>
"""

STRINGS = {
    "oneir_accessibility_service_description": (
        "Lets Vanya notice when you open a protected app, so she can check in "
        "before you start scrolling. Oneir never reads what\\'s on your screen."
    ),
    "widget_todays_focus_description": "Today\\'s Focus -- see your top 3 tasks at a glance",
    "widget_quick_focus_description": "Quick Focus -- start a 25-minute session with one tap",
    "widget_checkin_description": "Vanya Daily Check-in -- add a task without opening the app",
}


def fail(msg):
    print(f"wire_native.py: ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def step(msg):
    print(f"-- {msg}")


def copy_kotlin_files():
    step("Copying Kotlin sources into android/app/.../kotlin/com/oneir/app/")
    PKG_DIR.mkdir(parents=True, exist_ok=True)
    sources = list((NATIVE / "kotlin").glob("*.kt")) + list((NATIVE / "widgets" / "kotlin").glob("*.kt"))
    if not sources:
        fail("no Kotlin source files found under android_native_files/")
    for src in sources:
        dest = PKG_DIR / src.name
        shutil.copy2(src, dest)
        print(f"   {src.relative_to(ROOT)} -> {dest.relative_to(ROOT)}")


def copy_res_files():
    step("Copying widget/accessibility resource XML")
    xml_dir = RES / "xml"
    layout_dir = RES / "layout"
    drawable_dir = RES / "drawable"
    for d in (xml_dir, layout_dir, drawable_dir):
        d.mkdir(parents=True, exist_ok=True)

    for src in [NATIVE / "xml" / "oneir_accessibility_service_config.xml"] + list(
        (NATIVE / "widgets" / "xml").glob("*.xml")
    ):
        shutil.copy2(src, xml_dir / src.name)
        print(f"   {src.relative_to(ROOT)} -> {(xml_dir / src.name).relative_to(ROOT)}")

    for src in (NATIVE / "widgets" / "layout").glob("*.xml"):
        shutil.copy2(src, layout_dir / src.name)
        print(f"   {src.relative_to(ROOT)} -> {(layout_dir / src.name).relative_to(ROOT)}")

    for src in (NATIVE / "widgets" / "drawable").glob("*.xml"):
        shutil.copy2(src, drawable_dir / src.name)
        print(f"   {src.relative_to(ROOT)} -> {(drawable_dir / src.name).relative_to(ROOT)}")


def merge_strings():
    step("Merging strings.xml")
    strings_path = RES / "values" / "strings.xml"
    strings_path.parent.mkdir(parents=True, exist_ok=True)

    if strings_path.exists():
        text = strings_path.read_text(encoding="utf-8")
    else:
        text = '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n</resources>\n'

    missing = {k: v for k, v in STRINGS.items() if f'name="{k}"' not in text}
    if not missing:
        print("   already up to date")
        return

    entries = "\n".join(f'    <string name="{k}">{v}</string>' for k, v in missing.items())
    if "</resources>" not in text:
        fail(f"{strings_path} has no </resources> closing tag -- can't merge safely")
    text = text.replace("</resources>", f"{entries}\n</resources>")
    strings_path.write_text(text, encoding="utf-8")
    print(f"   added {len(missing)} string(s)")


def merge_manifest():
    step("Merging AndroidManifest.xml")
    if not MANIFEST.exists():
        fail(f"{MANIFEST} doesn't exist -- did `flutter create .` run first?")
    text = MANIFEST.read_text(encoding="utf-8")

    if MARKER in text:
        print("   already wired, skipping")
        return

    # Ensure the tools: namespace is declared (AndroidManifest_additions.xml
    # uses tools:ignore on the usage-stats permission).
    manifest_tag_match = re.search(r"<manifest\b[^>]*>", text)
    if not manifest_tag_match:
        fail("couldn't find <manifest ...> opening tag")
    manifest_tag = manifest_tag_match.group(0)
    if "xmlns:tools=" not in manifest_tag:
        new_tag = manifest_tag.replace(
            "<manifest ", '<manifest xmlns:tools="http://schemas.android.com/tools" ', 1
        )
        text = text.replace(manifest_tag, new_tag, 1)
        manifest_tag = new_tag

    # Insert manifest-level additions right after <manifest ...>, before
    # <application ...> (order among manifest children doesn't matter to
    # the Android tooling).
    text = text.replace(
        manifest_tag,
        manifest_tag + "\n" + MARKER + MANIFEST_LEVEL_ADDITIONS,
        1,
    )

    # Insert application-level additions right before the FIRST
    # </application> closing tag.
    if "</application>" not in text:
        fail("couldn't find </application> closing tag")
    text = text.replace(
        "</application>",
        APPLICATION_LEVEL_ADDITIONS + "    </application>",
        1,
    )

    MANIFEST.write_text(text, encoding="utf-8")
    print("   inserted permissions, <queries>, service, activity, receivers")


GOOGLE_SERVICES_VERSION = "4.4.2"


def wire_firebase():
    """
    Copies google-services.json into place and applies the Google Services
    Gradle plugin, IF android_native_files/google-services.json exists.
    Skipped (not failed) when it doesn't -- Firebase is optional, and a
    build without it should still succeed (Firebase.initializeApp() fails
    gracefully at runtime already, see lib/main.dart).

    Handles both the Groovy (settings.gradle / build.gradle) and Kotlin DSL
    (settings.gradle.kts / build.gradle.kts) templates Flutter's `flutter
    create` can generate, since which one "the stable channel" produces can
    change between Flutter releases and this script can't detect that in
    advance. Anchors on substrings ("com.android.application",
    "flutter-gradle-plugin") that are stable across both syntaxes rather
    than on exact quote/version strings that aren't.
    """
    src = NATIVE / "google-services.json"
    if not src.exists():
        step("No android_native_files/google-services.json yet -- skipping Firebase Gradle wiring "
             "(app will still build; Firebase features stay off until you add this file, see SETUP.md)")
        return

    step("Wiring Firebase (google-services.json + Gradle plugin)")
    app_dir = ANDROID / "app"
    dest = app_dir / "google-services.json"
    shutil.copy2(src, dest)
    print(f"   {src.relative_to(ROOT)} -> {dest.relative_to(ROOT)}")

    settings_groovy = ANDROID / "settings.gradle"
    settings_kts = ANDROID / "settings.gradle.kts"
    settings_path = settings_kts if settings_kts.exists() else settings_groovy
    if not settings_path.exists():
        fail("neither android/settings.gradle nor android/settings.gradle.kts exists -- "
             "was `flutter create .` run before this script?")

    is_kts = settings_path.suffix == ".kts"
    settings_text = settings_path.read_text(encoding="utf-8")

    if "google-services" not in settings_text:
        anchor = re.search(r'^.*com\.android\.application.*$', settings_text, re.MULTILINE)
        if not anchor:
            fail(
                f"couldn't find a 'com.android.application' plugin line in {settings_path.relative_to(ROOT)} "
                "to anchor the Google Services plugin insertion. Add this line yourself right after it:\n"
                + ('    id("com.google.gms.google-services") version "' + GOOGLE_SERVICES_VERSION + '" apply false'
                   if is_kts else
                   '    id "com.google.gms.google-services" version "' + GOOGLE_SERVICES_VERSION + '" apply false')
            )
        new_line = (
            f'    id("com.google.gms.google-services") version "{GOOGLE_SERVICES_VERSION}" apply false'
            if is_kts else
            f'    id "com.google.gms.google-services" version "{GOOGLE_SERVICES_VERSION}" apply false'
        )
        settings_text = settings_text.replace(anchor.group(0), anchor.group(0) + "\n" + new_line, 1)
        settings_path.write_text(settings_text, encoding="utf-8")
        print(f"   added google-services plugin declaration to {settings_path.relative_to(ROOT)}")
    else:
        print(f"   {settings_path.relative_to(ROOT)} already references google-services, skipping")

    app_build_kts = app_dir / "build.gradle.kts"
    app_build_groovy = app_dir / "build.gradle"
    app_build_path = app_build_kts if app_build_kts.exists() else app_build_groovy
    if not app_build_path.exists():
        fail("neither android/app/build.gradle nor android/app/build.gradle.kts exists.")

    is_app_kts = app_build_path.suffix == ".kts"
    app_build_text = app_build_path.read_text(encoding="utf-8")

    if "google-services" not in app_build_text:
        anchor = re.search(r'^.*flutter-gradle-plugin.*$', app_build_text, re.MULTILINE)
        if not anchor:
            fail(
                f"couldn't find a 'flutter-gradle-plugin' line in {app_build_path.relative_to(ROOT)} "
                "to anchor the Google Services plugin insertion. Add this line yourself inside the "
                "plugins { } block:\n"
                + ('    id("com.google.gms.google-services")' if is_app_kts else '    id "com.google.gms.google-services"')
            )
        new_line = (
            '    id("com.google.gms.google-services")' if is_app_kts else '    id "com.google.gms.google-services"'
        )
        app_build_text = app_build_text.replace(anchor.group(0), anchor.group(0) + "\n" + new_line, 1)
        app_build_path.write_text(app_build_text, encoding="utf-8")
        print(f"   added google-services plugin application to {app_build_path.relative_to(ROOT)}")
    else:
        print(f"   {app_build_path.relative_to(ROOT)} already references google-services, skipping")


GEMMA_MIN_SDK = 30


def wire_gemma_min_sdk():
    """
    Bumps the generated app/build.gradle(.kts)'s minSdk to at least 30
    (Android 11) -- required by libLiteRtLm.so (the native library behind
    flutter_gemma_litertlm's .litertlm inference) regardless of whatever
    lower value Flutter's own default (flutter.minSdkVersion) would use.
    See lib/local_ai/model_info.dart's minSdkVersion doc comment.

    Deliberately does NOT hardcode `minSdk = 30` and drop the
    flutter.minSdkVersion reference entirely -- flutter/flutter#177141
    documents the Flutter Gradle plugin fighting with a fully-hardcoded
    value on some versions, re-overwriting it back to its own default on
    the next run. Using max(30, flutter.minSdkVersion) keeps the
    flutter.minSdkVersion reference intact (so Flutter's own tooling has
    no reason to "fix" it) while still guaranteeing at least 30 no matter
    what Flutter's shipped default is on a given release.

    Idempotent: skips if the anchor line was already patched (checks for
    the literal "30" already present alongside minSdk on that line).
    """
    app_dir = ANDROID / "app"
    app_build_kts = app_dir / "build.gradle.kts"
    app_build_groovy = app_dir / "build.gradle"
    app_build_path = app_build_kts if app_build_kts.exists() else app_build_groovy
    if not app_build_path.exists():
        fail("neither android/app/build.gradle nor android/app/build.gradle.kts exists.")

    is_kts = app_build_path.suffix == ".kts"
    text = app_build_path.read_text(encoding="utf-8")

    # Matches Flutter's generated default line in any of its current
    # forms: `minSdk = flutter.minSdkVersion` (newer, both kts and
    # Groovy) or `minSdkVersion flutter.minSdkVersion` (older Groovy,
    # no `=`).
    anchor = re.search(r"^(\s*)(minSdk(?:Version)?)(\s*=\s*|\s+)flutter\.minSdkVersion\s*$", text, re.MULTILINE)
    if not anchor:
        if re.search(r"minSdk\w*\s*=?\s*(maxOf|Math\.max)\(\s*30\s*,\s*flutter\.minSdkVersion", text):
            print(f"   {app_build_path.relative_to(ROOT)} already wired for Gemma's minSdk 30 floor, skipping")
            return
        fail(
            f"couldn't find a 'minSdk(Version) = flutter.minSdkVersion' line in {app_build_path.relative_to(ROOT)} "
            "to raise for Gemma 4 E2B (needs minSdk 30). Set it by hand: "
            + ("minSdk = maxOf(30, flutter.minSdkVersion)" if is_kts else
               "minSdkVersion Math.max(30, flutter.minSdkVersion as int)")
        )

    # Preserve whichever operator style (`=` property assignment vs. bare
    # `keyword value` method-call form) the generated file already used --
    # different AGP/Gradle versions accept different subsets of these, so
    # guessing based on kts-vs-not-kts alone risks emitting a form the
    # installed Gradle plugin version rejects. group(3) is either
    # " = "/"=" or plain whitespace, matching what was already there.
    indent, keyword, operator = anchor.group(1), anchor.group(2), anchor.group(3)
    uses_equals = "=" in operator
    if is_kts:
        # kts always uses property assignment; maxOf() is Kotlin's stdlib
        # equivalent of Math.max() and needs no cast (both args are Int).
        new_line = f"{indent}minSdk = maxOf({GEMMA_MIN_SDK}, flutter.minSdkVersion)"
    elif uses_equals:
        new_line = f"{indent}{keyword} = Math.max({GEMMA_MIN_SDK}, flutter.minSdkVersion as int)"
    else:
        new_line = f"{indent}{keyword} Math.max({GEMMA_MIN_SDK}, flutter.minSdkVersion as int)"

    text = text.replace(anchor.group(0), new_line, 1)
    app_build_path.write_text(text, encoding="utf-8")
    step("Raised minSdk for on-device Gemma (flutter_gemma_litertlm requires API 30+)")
    print(f"   {app_build_path.relative_to(ROOT)}: {anchor.group(0).strip()!r} -> {new_line.strip()!r}")


def verify_package_dir():
    # Sanity check that flutter create actually used the org/name we asked
    # for -- if it didn't, every .kt file's `package com.oneir.app` line
    # won't match the folder Gradle expects it in, and the build will fail
    # with a confusing "class not found" error instead of this clear one.
    if not PKG_DIR.exists():
        fail(
            f"expected package directory {PKG_DIR.relative_to(ROOT)} doesn't exist. "
            "Re-run `flutter create .` with `--org com.oneir --project-name app` "
            "so the generated applicationId is com.oneir.app, matching the "
            "`package com.oneir.app` line in every android_native_files/**/*.kt file."
        )


WIDGET_TEST = ROOT / "test" / "widget_test.dart"

WIDGET_TEST_CONTENTS = """\
// Every `flutter create .` run overwrites this file with a default
// template that references a placeholder `MyApp` widget -- this app's
// real root widget is `OneirApp` (lib/main.dart), which has never once
// matched that template, so the default version always failed
// `flutter analyze` with "MyApp isn't a class" (harmless -- analyze runs
// with `|| true` in CI -- but still noise on every single build). This
// script overwrites it right back with something that actually matches
// the app, the same way it patches every other `flutter create`d file.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('OneirApp builds without throwing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OneirApp()));
    // Just confirms the widget tree builds; the splash timer means we
    // don't wait for pumpAndSettle() here (it fires a real Timer).
    expect(find.byType(OneirApp), findsOneWidget);
  });
}
"""


def fix_widget_test():
    WIDGET_TEST.parent.mkdir(parents=True, exist_ok=True)
    WIDGET_TEST.write_text(WIDGET_TEST_CONTENTS)
    step("Replaced the default `flutter create` widget_test.dart template "
         "(referenced a nonexistent MyApp) with one that matches OneirApp")


def main():
    if not ANDROID.exists():
        fail("android/ doesn't exist yet -- run `flutter create . --platforms android "
             "--org com.oneir --project-name app` before this script.")
    verify_package_dir()
    copy_kotlin_files()
    copy_res_files()
    merge_strings()
    merge_manifest()
    wire_firebase()
    wire_gemma_min_sdk()
    fix_widget_test()
    step("Done. android/ is now fully wired -- no manual SETUP.md steps 1-3 remain.")


if __name__ == "__main__":
    main()
