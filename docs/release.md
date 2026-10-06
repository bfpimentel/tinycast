# Release

This personal fork ships one stable, ad-hoc signed arm64 DMG for macOS 26 (Tahoe) or later.
Homebrew installs and upgrades it; the app does not install its own updates.

## One-time setup

1. Commit and push `Casks/tinycast.rb` to
   [bfpimentel/homebrew-tap](https://github.com/bfpimentel/homebrew-tap).
2. Add `HOMEBREW_TAP_TOKEN` to **bfpimentel/tinycast → Settings → Secrets and variables → Actions**.
   Use a fine-grained PAT with **Contents: read/write** on `bfpimentel/homebrew-tap`.

That is the only configured release secret. GitHub supplies its own token for publishing the release.
No signing certificate, Apple Developer account, keychain setup or signing secrets are needed.
Signing and the permission trade-off are described in [signing.md](signing.md).

## Publish a release

Push your changes, then open **Actions → Release → Run workflow** and enter a new stable version,
such as `0.11.13`. Only `MAJOR.MINOR.PATCH` versions are accepted.

The workflow runs on `macos-26` with Xcode 26 and:

1. Validates the version, tap token and committed cask before building.
2. Runs `Scripts/build-dmg.sh` to build and package the arm64 app and both helpers.
3. Checks the macOS floor, architectures, ad-hoc seals and runtime entitlements.
4. Publishes `Tinycast-<version>.dmg` as GitHub Release `v<version>`, targeting the built commit.
   GitHub generates the changelog; the notes also include the Homebrew commands.
5. Updates the version and SHA-256 in the tap's `Casks/tinycast.rb` and pushes that change.

Release runs are serialized so tap updates cannot race. There are no beta/universal jobs, ZIP
artifacts, Discord announcements or website rebuilds. The checksum covers the actual uploaded DMG.
The cask's version/checksum lines retain their two-space indent for the anchored replacement.

## Install and upgrade

```sh
brew trust --tap bfpimentel/tap
brew install --cask bfpimentel/tap/tinycast
brew upgrade --cask bfpimentel/tap/tinycast
```

Trust the third-party tap once before installing. The cask deliberately does not declare
`auto_updates true`: Homebrew must track its version.
It declares `depends_on macos: :tahoe` (Tahoe or later) and `depends_on arch: :arm64`, and clears
download quarantine during installation and upgrades. A directly downloaded DMG is not notarized;
clear quarantine on the installed app with
`xattr -dr com.apple.quarantine "/Applications/Tinycast.app"` if needed.

## Build a DMG locally

```sh
./Scripts/build-dmg.sh            # version from project.yml
./Scripts/build-dmg.sh 0.11.13     # -> build/Tinycast-0.11.13.dmg
```

This is the same certificate-free build, verification and packaging path CI uses. Xcode is selected
by `xcode-select` or an explicitly provided `DEVELOPER_DIR`. It preserves the existing bundle id
`com.tinycast.app`, application name and data locations.
