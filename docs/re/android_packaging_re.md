# Android packaging: icon, splash, signing

Evidence: tools/re/export_exe_icon.py, .github/workflows/build-android.yml, app/art/screens/title/fondo7.png
  -- the PE resource-tree icon exporter, the workflow that ships the APK, and the extracted title frame used as the splash.

Status: **icon + splash BUILT 2026-07-27 from the original's own files; release signing
WIRED and waiting on one repository secret.** Nothing here is drawn or invented.

## 1. The launcher icon is the game's own

Godot's default `icon.svg` shipped as the app icon until now. The faithful source was
sitting in the executable the whole time: `MANAGER.EXE`'s PE `.rsrc` section holds four
`RT_ICON` entries and one `RT_GROUP_ICON` —

| entry | size | bpp |
|---|---|---|
| 1 | 16x16 | 4 |
| 2 | 16x16 | 8 |
| 3 | 32x32 | 4 |
| **4** | **32x32** | **8** |

Entry 4 is the largest and is what Windows drew for the game: a football.
`tools/re/export_exe_icon.py` walks the three-level resource tree, decodes the
`BITMAPINFOHEADER` + palette + XOR bits + AND mask by hand, and writes

* `app/art/icons/app_icon.png` — 32x32, exactly the resource bitmap (the project icon)
* `app/art/icons/app_icon_192.png` — 192x192, **nearest-neighbour 6x** (the launcher icon)

Integer scale and no filtering, so the 1998 pixels stay hard.

**Deliberately NOT shipped: an adaptive icon.** Android's adaptive format needs a
background LAYER, and the original has no such thing — the title screen is a gradient,
not a flat plate, so there is no honest pixel to sample and any colour would be a guess.
Launchers mask a legacy icon themselves, so the only thing given up is the choice of mask.
`launcher_icons/adaptive_*` stay empty on purpose; do not "fix" them with a made-up plate.

`app/icon.svg` (Godot's template icon) is deleted.

## 2. The boot splash is the game's own title frame

`application/boot_splash/image = res://art/screens/title/fondo7.png` — the extracted 640x480
frame the real game opens on. `use_filter=false` and `fullsize=false`, so it is drawn 1:1
and centred over the app's dark backdrop rather than stretched: the same letterboxing the
game itself gets from `display/window/stretch` (`keep`, 640x480, landscape-locked).

## 3. Release signing

`.github/workflows/build-android.yml` exports **release-signed when the key is available
and debug-signed otherwise**, so a fork or a fresh clone still builds.

The switch is the secret `ANDROID_RELEASE_KEYSTORE_BASE64`. When it is set the workflow
decodes it to `release.keystore`, sets `BUILD_MODE=release`, and exports with
`--export-release`; otherwise `--export-debug`, exactly as before.

**Verified against the shipped engine, not assumed:** Godot 4.6 has NO
`export/android/release_keystore` editor setting — `strings` on the binary shows only the
three `export/android/debug_keystore*` keys. The release key reaches the exporter through
its own environment variables instead:

```
GODOT_ANDROID_KEYSTORE_RELEASE_PATH
GODOT_ANDROID_KEYSTORE_RELEASE_USER
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
```

which is also why the password never lands in a file on the runner. (The export preset's
own `keystore/release*` options exist too, but they would have to be committed.)

### Turning it on — one time, by the owner

Generating the key is NOT automated, and should not be: a release key is the owner's to
hold, and one generated per CI run would be worthless — Android identifies an app by its
signature, so a new key every build means every update is a different app.

```bash
keytool -genkeypair -v -keystore pm98-release.keystore -alias pm98 \
  -keyalg RSA -keysize 4096 -validity 10000 -storetype PKCS12
base64 -w0 pm98-release.keystore        # paste as ANDROID_RELEASE_KEYSTORE_BASE64
```

then add, under Settings -> Secrets and variables -> Actions:

| secret | value |
|---|---|
| `ANDROID_RELEASE_KEYSTORE_BASE64` | the base64 above |
| `ANDROID_RELEASE_KEY_ALIAS` | `pm98` |
| `ANDROID_RELEASE_KEYSTORE_PASSWORD` | the store password |

**Keep `pm98-release.keystore` somewhere safe and backed up.** Lose it and the installed
app can never be updated in place again — only uninstalled and reinstalled.

Version stamped for this build: `version/code=3`, `version/name="0.2.0"`.

## 4. What a device pass still has to check by hand

Not doable from this box (it can drive the Godot app, but not run the built APK):

* touch targets against the 640x480 design grid on a real panel — the hit rects are the
  original's own button rects, so a small control is small by design; whether that needs a
  per-widget touch inflation is a device judgement, not a source question;
* the letterboxed layout on a tall phone (the `resizable=false` +
  `handheld/orientation=4` pair was already the fix for the "half title screen" report);
* that the launcher shows the football on the owner's own launcher/mask;
* first-run storage permission-free start (the app writes only to `user://`).
