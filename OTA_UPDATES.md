# OTA updates

The Android app checks the latest production GitHub Release at startup and
offers newer APKs through Android's package installer. It does not use Google
Play.

## Release workflow

1. Increase `version` in `pubspec.yaml`. The value after `+` must increase for
   every Android release.
2. Commit and push the version change:

   ```powershell
   git add .
   git commit -m "new version"
   git push origin main
   ```

3. GitHub Actions detects the version change, creates the matching tag, builds
   and signs `utang-tracker.apk`, calculates its SHA-256, creates
   `update-manifest.json`, and publishes the GitHub Release. Commits that do not
   change the version only run quality checks.

## GitHub secrets

Configure these repository Actions secrets before pushing a new version:

- `ANDROID_RELEASE_KEYSTORE_BASE64`: base64-encoded release keystore
- `ANDROID_STORE_PASSWORD`: keystore password
- `ANDROID_KEY_PASSWORD`: key password
- `ANDROID_KEY_ALIAS`: key alias

Encode the local keystore for the first secret with:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('android/app/upload-keystore.jks'))
```

The APK must use the same release certificate as the installed app. Android
requires the user to allow installs from this app and confirm each installation.
The app verifies HTTPS, package name, version code, SHA-256, and signing
certificate before opening the installer.

Set `required` to `true` to remove the Later action. Keep the release keystore
and `android/key.properties` backed up securely; losing the certificate makes
future in-place updates impossible.

`UPDATE_MANIFEST_URL` remains available as a build-time override for testing,
but normal production builds use this repository's latest GitHub Release.
