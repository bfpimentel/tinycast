# Updates

This personal build is updated through Homebrew, not the in-app updater.

## Invariants

- `com.tinycast.app` resolves to `ReleaseChannel.homebrew`; `com.tinycast.app.dev` is development.
  Neither fetches releases, starts an update timer, offers cached updates or installs app updates.
- The Homebrew cask omits `auto_updates true`, so `brew upgrade` owns version tracking.
- The launcher does not advertise Check for Updates. The app menu, menu-bar item and About view
  omit the action; General → App Updates provides the Homebrew command instead.
- A saved Check for Updates hotkey reports the Homebrew command without requesting a release.
- An imported preference or stale update cache cannot re-enable self-updating.
- The upstream installer's signature verification is unchanged. Disabling the updater does not
  weaken its trust checks or add an ad-hoc-signature bypass.
- Raycast extension updates are independent and continue to work.

## Installing updates

```sh
brew upgrade --cask bfpimentel/tap/tinycast
```

The release workflow builds one arm64 DMG and updates its version and checksum in
`bfpimentel/homebrew-tap`. It produces no updater ZIP or universal/beta artifacts.
See [release.md](../release.md) for the one-secret workflow and
[signing.md](../signing.md) for ad-hoc signing and possible permission re-prompts.

## Runtime policy

ReleaseChannel takes the bundle id as an injected parameter. The Homebrew channel accepts no
in-app release, and `updatesItself` is false. UpdateCheckStore does not load an update cache for
this channel, and guards both automatic and manual checks as well as its offer accessors.
UpdateCoordinator also guards announcement and installation paths.

The upstream updater's parsing, storage and installer implementation remain isolated under this
feature for minimal upstream merge churn. Tests can still inject its stable/beta channels directly.
The existing `automaticallyCheckForUpdates` settings-file/backup field is inert for Homebrew builds;
it cannot override the channel policy.

## Verification

`updates-test` checks Homebrew channel derivation and rejection of both release kinds.
`update-check-test` proves automatic/manual requests remain at zero, a seeded cache produces no
offer, and the unused file stays untouched. The existing tests still guard the retained updater's
parsing, cancellation and trust policy inputs.
