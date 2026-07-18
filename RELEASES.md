# Android releases

GitHub Actions publishes a signed Android APK when the version in
`pubspec.yaml` changes on the `main` branch. The APK is available from the
matching GitHub Release for manual download and installation.

## Release workflow

1. Increase `version` in `pubspec.yaml`. The value after `+` must increase for
   every Android release.
2. Commit and push the version change to `main`.
3. GitHub Actions runs the quality checks, creates the matching version tag,
   builds and signs `utang-tracker.apk`, and publishes the GitHub Release.
   Commits that do not change the version only run quality checks.

## GitHub secrets

Configure these repository Actions secrets before publishing a release:

- `ANDROID_RELEASE_KEYSTORE_BASE64`: base64-encoded release keystore
- `ANDROID_STORE_PASSWORD`: keystore password
- `ANDROID_KEY_PASSWORD`: key password
- `ANDROID_KEY_ALIAS`: key alias

Encode the local keystore for the first secret with:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('android/app/upload-keystore.jks'))
```

Keep the release keystore and `android/key.properties` backed up securely.
Android requires future versions of an installed app to use the same signing
certificate.
