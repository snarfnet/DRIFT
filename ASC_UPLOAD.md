# App Store Connect Upload

Bundle ID: `com.tokyonasu.Drift`

GitHub Actions can upload a signed IPA to App Store Connect with the workflow `Upload to App Store Connect`.

## Required GitHub Secrets

- `BUILD_CERTIFICATE_BASE64`: Apple Distribution `.p12` encoded with base64.
- `P12_PASSWORD`: Password for the `.p12` file.
- `BUILD_PROVISION_PROFILE_BASE64`: App Store provisioning profile encoded with base64.
- `IOS_PROFILE_NAME`: Provisioning profile name, exactly as shown in Apple Developer.
- `KEYCHAIN_PASSWORD`: Any strong temporary password for the CI keychain.
- `ASC_KEY_ID`: App Store Connect API key ID.
- `ASC_ISSUER_ID`: App Store Connect issuer ID.
- `ASC_API_KEY_BASE64`: App Store Connect `.p8` key encoded with base64.

## Apple Setup

1. Create an App ID in Apple Developer with `com.tokyonasu.Drift`.
2. Create an App Store provisioning profile for that App ID.
3. Create or export an Apple Distribution certificate as `.p12`.
4. In App Store Connect, create the app record using Bundle ID `com.tokyonasu.Drift`.
5. Add the GitHub Secrets above.
6. Run the `Upload to App Store Connect` workflow from GitHub Actions.

