# JunkYardRush — Godot 4 Mobile Game

A native Godot 4 (GDScript) mobile game targeting **Android (Google Play)** and
**iOS (App Store)**. Mobile-first architecture: portrait, touch, safe-area
aware, responsive across screen sizes and densities, low-end friendly.

> Project milestone: **Prototype** (step 1 of the roadmap below). Gameplay,
> progression, art, audio, optimization and store builds are progressively
> layered on top of this base.

## Roadmap

1. Prototype Godot 4 ✅ (this commit)
2. Gameplay principal
3. Système de progression
4. Graphismes définitifs
5. Sons et musiques
6. Interface mobile
7. Optimisation Android/iOS
8. Tests sur appareils réels
9. Build de production Android
10. Publication Google Play
11. Build de production iOS
12. Publication App Store

## Engine / tech

- **Godot 4.x** (project file targets 4.7 features), GDScript.
- Renderer: `gl_compatibility` (broad mobile support; Vulkan/Metal revisitable
  later for high-end devices without changing gameplay code).
- Portrait by default; orientation centralized in `AppConfig.ORIENTATION` +
  `project.godot` `window/handheld/orientation`.
- Safe-area insets (notches, home indicator) handled by `SafeAreaContainer`.
- Minimum touch targets enforced by `TouchButton` (≥ 56dp).
- Local save via `user://` (cross-platform app sandbox).

## Project layout

```
project.godot              App identity, autoloads, display, rendering, input
export_presets.cfg         Android (Debug/Release AAB) + iOS (Debug/Release) + Linux
icon.svg / icon.png        Godot project icon (brand)
assets/android/            Launcher icons (mdpi…xxxhdpi) + Play Store 512px
assets/ios/                AppIcon.appiconset (all required sizes) + splash
src/autoload/              AppConfig, GameManager, SaveManager, AudioManager,
                          SceneManager, HapticManager
src/scenes/                boot, menu, game (player + junk collection)
src/ui/widgets/            SafeAreaContainer, TouchButton
src/ui/screens/            GameHud
src/data/translations.csv  en/fr localization (CSV -> compiled by Godot)
```

## App identity (change before publishing!)

Single source of truth lives in two places — keep them in sync:

- `src/autoload/app_config.gd` → `APP_NAME`, `BUNDLE_IDENTIFIER`, `VERSION`,
  `VERSION_CODE`, `COMPANY_NAME`.
- `project.godot` → `config/name`, `config/version`, `config/version_code`,
  `config/bundle_identifier`, `config/company_name`, `config/product_name`.
- `export_presets.cfg` → Android `package/unique_name`, iOS
  `application/app_identifier`, version/code.

Replace `com.yourstudio.junkyardrush` with your real studio prefix, e.g.
`com.mystudio.junkyardrush`. **Do not ship `com.yourstudio…` or
`com.example…`.**

## Bumping version

- Semantic `VERSION` string (e.g. `0.1.0`) → `config/version` /
  Android `version/name` / iOS `short_version`.
- Integer `VERSION_CODE` (monotonic) → `config/version_code` /
  Android `version/code` / iOS `version`. **Increment on every Play Store
  upload.**

## Running

Open the project in Godot 4 (Editor). On first open Godot imports assets and
regenerates `.import` files (the `.godot/` cache is git-ignored). Press F5 /
Play — `BootScene` initializes autoloads, applies orientation, then routes to
the main menu.

## Android export

Requirements: Godot 4 editor + Android build template (Gradle). The presets
use **Gradle custom build** (`gradle_build/use_gradle_build=true`) so you can
drop Android-specific Gradle config / dependencies later.

1. In Godot: **Editor → Editor Settings → Export → Android** set the path to
   your Android `sdk` and install the Godot Android export template.
2. **Project → Export → Add… → Android**, pick the `Android (Debug)` or
   `Android (Release)` preset already in `export_presets.cfg`.
3. Debug: export APK to `export/android/JunkYardRush-debug.apk`.
4. Release (Play Store): export **AAB** to
   `export/android/JunkYardRush-release.aab` (format `export_format=1`).

### Android signing (Release)

**Never commit keystore credentials.** `.gitignore` already excludes
`*.keystore`, `*.jks`, `*.p12`, `*.env`, and `secrets/`.

To sign a release build:

1. Generate (once, offline):
   ```
   keytool -keyalg RSA -genkeypair -alias junkyardrush \
     -keystore secrets/junkyardrush.keystore -storepass <...> \
     -validity 10000 -keysize 4096
   ```
   (keep `secrets/` outside version control — it is git-ignored).
2. In the Godot Android export preset, set:
   - `keystore/release` = path to your keystore
   - `keystore/release_user` = alias
   - `keystore/release_password` = store/key password
   Prefer reading these from a local (git-ignored) override or env rather than
   typing into the shared preset.

### Android permissions

Only `android.permission.VIBRATE` is enabled (for haptics). Everything else
(internet, storage, location, camera, etc.) is **off**. Add a permission only
when a feature truly requires it, and document why.

- `min_sdk_version=24` (Android 7.0+), `target_sdk_version=34` (Play Store
  current requirement).
- `arm64-v8a` only (modern devices; keeps APK small). Re-enable `armeabi-v7a`
  if you must support very old devices.

## iOS export

Requirements: **macOS** + Xcode + Apple Developer account + provisioning
profile. The final signing/archive/`ipa` cannot be produced on this Linux dev
box — that step must run on macOS. This project is *prepared* for it.

1. In Godot (on macOS): install the iOS export template.
2. **Project → Export → iOS**, pick `iOS (Debug)` or `iOS (Release)`.
3. Set:
   - `application/app_identifier` = your bundle id (matches Android).
   - `application/signing` = `Debug` / `Distribution`.
   - Provisioning profile UUIDs.
4. Export generates an `.xcodeproj`; open in Xcode, select your signing team,
   archive, and upload to App Store Connect via Xcode or `altool`/Transporter.

### iOS capabilities

All capabilities (Game Center, IAP, push, camera, mic, etc.) are **off**.
Enable only what a feature needs. App uses `vibrate_handheld` (haptics) which
is covered by the default entitlements on iOS.

### Privacy

`privacy/*` usage strings are empty. Before submitting, add a description for
any capability you enable (Apple rejects empty strings for active
capabilities).

## Secrets / security

- No API keys, tokens, or passwords live in the repo.
- Save data is local-only (`user://`). Cloud sync, if added later, must read
  credentials from env / a git-ignored config, never from source.
- `.gitignore` blocks signing material and `.env`. Review any PR that touches
  `export_presets.cfg`, `*.gradle`, `Info.plist`, or signing config.

## Localization

`src/data/translations.csv` is a multi-language CSV loaded at runtime by
`AppConfig` (not via Godot's translation importer) into `TranslationServer`.
Add a language by adding a column (e.g. `es`) and referencing strings via
`tr("KEY")`. Fallback locale is `en`. Missing/empty values are skipped, so
partial translations don't break startup.

## Orientation change

Portrait is the default. To switch to landscape:

1. `src/autoload/app_config.gd`: `ORIENTATION = "landscape"`.
2. `project.godot`: swap `viewport_width`/`viewport_height` and set
   `window/handheld/orientation="landscape"`.
3. Re-anchor UI containers (SafeAreaContainer adapts insets automatically).

## License

All rights reserved (placeholder). Set the real license before publishing.
