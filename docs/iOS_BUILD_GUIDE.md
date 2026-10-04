# Noir Player — iOS Build Guide (GitHub Actions)

This project is developed without a Mac. The iOS app is built entirely on
GitHub's `macos-latest` runners and delivered as an IPA artifact.

- **Unsigned by default** — no Apple certificate needed to run the pipeline.
- **Signed on demand** — once you provide the Apple secrets described below.

Discover needs no build-time configuration on iOS either: it talks to Noir
Player's server, and users can add their own API keys in **Settings → Discover**.

---

## 1. How the pipeline works

```
push / PR / manual / v* tag
   │
   ▼
macos-latest runner
   │
   ├─ Set up Flutter 3.35.7 (same version as the Android CI workflow)
   ├─ Bootstrap ios/ platform folder         (flutter create --platforms=ios . + overlays)
   ├─ flutter pub get
   ├─ dart run flutter_launcher_icons        (iOS app icons from assets/icon/app_icon.png)
   ├─ pod install                            (CocoaPods, cached)
   ├─ ── unsigned ──► flutter build ios --release --no-codesign
   │                   └─ package build/ios/iphoneos/Runner.app → NoirPlayer-unsigned.ipa
   ├─ ── signed ──► import .p12 cert + install .mobileprovision
   │                   └─ flutter build ipa --release --export-options-plist ios/ExportOptions.plist
   └─ Upload IPA as a GitHub Actions artifact
```

Because the generated Xcode project is not in git,
`.github/scripts/ios_bootstrap.sh` regenerates it on the runner and keeps the
**version-controlled** files:

| File | Purpose |
|---|---|
| `ios/Podfile` | Deployment target 13.0 + `permission_handler` macros |
| `ios/Runner/Info.plist` | Permissions, background audio, display name |
| `ios/ExportOptions.plist` | Signing/export method (`METHOD_PLACEHOLDER`, `TEAM_ID_PLACEHOLDER`) |

## 2. iOS-related files

| File | Role |
|---|---|
| `.github/workflows/ios.yml` | The iOS CI workflow |
| `.github/scripts/ios_bootstrap.sh` | Generates + configures `ios/` |
| `ios/Podfile` | CocoaPods + deployment target + permission macros |
| `ios/Runner/Info.plist` | iOS permissions + display name |
| `ios/ExportOptions.plist` | Export options template |
| `pubspec.yaml` | `ios: true` in the launcher-icons config |
| `lib/.../songs_tab.dart` | iOS permission gate (see §9) |
| `lib/.../music_discovery_service.dart` | iOS download folder + storage guard (see §9) |
| `.gitignore` | iOS ignore rules (Pods, Generated.xcconfig, …) |

## 3. Secrets — full reference

Set these in **GitHub → Settings → Secrets and variables → Actions**.
None are needed for the default unsigned build.

### Required only for a SIGNED build

| Secret | Required? | What it is / how to create it |
|---|---|---|
| `APPLE_TEAM_ID` | Signed only | 10-character Team ID. Apple Developer → Membership. |
| `IOS_BUNDLE_ID` | Signed only | Bundle identifier, e.g. `com.yourname.noirplayer`. Must match the App ID & provisioning profile. |
| `APPLE_CERT_P12_BASE64` | Signed only | Base64 of your **distribution certificate** `.p12` (see §4). |
| `APPLE_CERT_P12_PASSWORD` | Signed only | Password you set when exporting the `.p12`. Leave unset if the `.p12` is unencrypted. |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Signed only | Base64 of your `.mobileprovision` for `IOS_BUNDLE_ID` (see §4). |

### Repository variable (alternative to the manual input)

| Variable | Use |
|---|---|
| `IOS_SIGNING_ENABLED` | Set to `true` to force a **signed** build on every push/PR. Leave unset for unsigned. |

> `IOS_SIGNING_ENABLED` is a **Variable** (Settings → Secrets and variables →
> Actions → Variables), not a secret.

## 4. Obtaining the Apple certificates and provisioning profile

1. **App ID** — Apple Developer → Certificates, Identifiers & Profiles →
   Identifiers → `+` → App ID → set the Bundle ID you will use for
   `IOS_BUNDLE_ID`. Enable **Audio** under Background Modes (Capabilities).
2. **Distribution certificate** — Xcode → Settings → Accounts → Manage
   Certificates → `+` → *Apple Distribution*. (Or create one in the Apple
   Developer portal.) This certificate must have a **private key**.
3. **Export the `.p12`** — Keychain Access → right-click the certificate →
   Export → *Personal Information Exchange (.p12)* → set a password.
   Encode it for the secret:
   ```bash
   base64 -i YourCert.p12 -o cert.b64        # macOS
   certutil -encode YourCert.p12 cert.b64    # Windows
   ```
   Paste the **entire** contents of `cert.b64` into `APPLE_CERT_P12_BASE64`.
4. **Provisioning profile** — Apple Developer → Profiles → `+` → *Ad Hoc* or
   *App Store Connect* → select the App ID and the distribution certificate.
   Download the `.mobileprovision`, then:
   ```bash
   base64 -i YourProfile.mobileprovision -o profile.b64
   ```
   Paste the contents into `APPLE_PROVISIONING_PROFILE_BASE64`.

## 5. Enabling signing

Two ways:

1. **Per run (manual)** — Actions → **Build iOS IPA** → Run workflow →
   set **signing_enabled** to `true` (and pick an export method).
2. **Always** — set the repository variable `IOS_SIGNING_ENABLED = true`.

The workflow fails fast (with a clear `::error::` message) if any signing
secret is missing. Nothing is ever hardcoded in the repo.

## 6. Triggering the workflow & downloading the IPA

- **Push** — `git push` to `main`, `feat/**` or `ci/**` triggers it
  automatically.
- **Pull request** — opening/updating a PR runs it.
- **Manual** — Actions tab → **Build iOS IPA** → Run workflow.

**Download the IPA:** open the workflow run → **Summary** → **Artifacts** →
download `noir-player-ios-<sha>`.

## 7. GitHub Releases (iOS)

Pushing a version tag builds the IPA **and** attaches it to that tag's GitHub
release:

```bash
git tag v1.1.3
git push origin v1.1.3
```

The release itself (title, notes, Android APK and checksums) is created by the
**Release** workflow (`release.yml`). The iOS `publish-release` job waits for
that release to appear and then uploads `NoirPlayer-v<version>-ios-unsigned.ipa`
(or `-ios.ipa` when signed) to it, replacing an older copy of the same file. It
never creates the release and never changes its title or notes. If the release
does not appear within about 45 minutes (for example because the Android
release failed), the job fails and the IPA stays available as a workflow
artifact; re-run the job once the release exists.

## 8. Does CI/CD only work on the `main` branch?

**No.** GitHub Actions runs the workflow file **from the branch that triggered
it**. There is one quirk:

- The **"Run workflow" UI button only appears once the workflow file is on the
  default branch** (`main`). On a feature branch you can still run it with the
  GitHub CLI:
  ```bash
  gh workflow run ios.yml --ref <branch> -f signing_enabled=false
  ```
- Secrets are repo-level and available on every branch (except `pull_request`
  events from forks).

## 9. Android settings mirrored on iOS

The Gradle/Kotlin/AGP settings themselves are Android-only, but the intent of
the Android manifest is mirrored in `ios/Runner/Info.plist`:

| Android (manifest) | iOS (Info.plist) |
|---|---|
| `READ_MEDIA_AUDIO` | `NSAppleMusicUsageDescription` |
| `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `MEDIA_CONTENT_CONTROL`, `MODIFY_AUDIO_SETTINGS` | `UIBackgroundModes = [audio]` |
| `READ/WRITE/MANAGE_EXTERNAL_STORAGE` | none (sandbox) — downloads saved to app `Documents/NoirPlayerDownloads` |
| `INTERNET` | none (all APIs are HTTPS) |
| `android:label = "Noir Player"` | `CFBundleDisplayName = "Noir Player"` |
| launcher icon | generated iOS AppIcon via `flutter_launcher_icons` |
| version (pubspec) | `CFBundleShortVersionString` / `CFBundleVersion` |

Two small Dart guards keep Android behaviour identical and make iOS work:

1. `songs_tab.dart` — on iOS, skips the storage/microphone gate. On iOS
   `Permission.audio` is the **microphone** and `Permission.storage` is
   unsupported, so the gate would never let the library load. The
   media-library permission is requested by `on_audio_query` itself.
2. `music_discovery_service.dart` — on iOS, downloads are written to the app's
   `Documents/NoirPlayerDownloads` folder, no storage permission is requested,
   and the Android media scan is skipped.

## 10. Troubleshooting

| Error | Fix |
|---|---|
| `::error::... Secrets are missing` | Add the signing secrets (§3) or set `signing_enabled=false`. |
| `PRODUCT_BUNDLE_IDENTIFIER` mismatch | Set `IOS_BUNDLE_ID` so it matches your App ID + profile. |
| `No matching provisioning profiles found` | Re-download the profile for the exact bundle ID + certificate, re-encode it. |
| `Signing for "Runner" requires a development team` | `APPLE_TEAM_ID` must be set for signed builds. |
| Artifact step `No files were found` | The build produced no IPA — scroll up in the logs; `flutter build` printed the real error. |
| `publish-release`: release not found | The Release workflow has not published the tag's release (yet). Fix that run, then re-run `publish-release`. |
