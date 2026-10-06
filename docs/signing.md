# Signing

This fork uses **ad-hoc signing**: `CODE_SIGN_IDENTITY="-"` in `project.yml` and the packaging script.
Xcode signs the app and both helpers automatically. No certificate, Apple Developer account,
keychain import or signing secrets are required for local builds or CI.

Ad-hoc signing seals the code but establishes no publisher identity. It is not Developer ID signing
or notarization. The Homebrew cask clears download quarantine during installation and upgrades;
this is not a notarization ticket or an exemption from system security policy.

## Permissions after upgrades

A stable bundle id keeps preferences, caches and the login item in the same locations. It does not
guarantee stable TCC authorization under ad-hoc signing: macOS may require Accessibility, Input
Monitoring or other permissions to be granted again after a rebuild or upgrade.

If macOS retains an authorization that no longer works, remove and re-add Tinycast under
**System Settings → Privacy & Security** for that permission.

## Runtime and entitlements

Release builds keep the hardened runtime on the app and both helpers. Debug leaves it off so
Xcode's debug dylib can load without a certificate-backed Team ID.

The main app's entitlements remain in `Tinycast/Tinycast.entitlements`:

| Entitlement | Purpose |
| --- | --- |
| `com.apple.security.cs.allow-jit` | JavaScriptCore JIT |
| `com.apple.security.automation.apple-events` | Apple events and their permission prompt |
| `com.apple.security.device.camera` | Camera permission |
| `com.apple.security.personal-information.calendars` | Calendar permission |

A usage string alone is insufficient under the hardened runtime; its matching entitlement must be
present before macOS will offer a permission prompt. `Scripts/verify-signature.sh` verifies the
ad-hoc signatures, nested seal, helper bundle identity, runtime flags, absence of Debug's
`get-task-allow`, and each protected resource's declared entitlement.

## Updates

Homebrew owns app updates. The shipped bundle resolves to `ReleaseChannel.homebrew` and cannot
fetch, offer or install an in-app update, including one left in an older update cache.
The dormant upstream installer retains its certificate-based trust checks; those checks are not
relaxed to accept arbitrary ad-hoc apps.
