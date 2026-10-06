# Dashboard

A read-only row above the palette's search field, owned by `Tinycast/Features/Dashboard/`.

## Invariants

- The dashboard has the same height in compact and expanded modes, and on every palette screen.
  It never remounts the search field or consumes a result-selection index.
- Both widgets use SwiftUI, the existing appearance-aware Theme tokens and InterfaceMetrics.
  DashboardLayout composes existing scaled tokens; no shared design tokens are changed.
- No polling or clock ticks while the palette is hidden. Workspace state is transient view state,
  not a preference or a second app-wide owner.
- AeroSpace is queried only: the widget never switches workspaces or changes its configuration.

## Widgets

`DateClockWidget` displays local time, including seconds, and a weekday/month/day date using native
locale-aware formatting. Its TimelineView is mounted only while the palette is visible.

`AeroSpaceWorkspacesWidget` locates the user's CLI with the existing ExecutableLocator, then queries:

```sh
aerospace list-workspaces --all --format '%{workspace}%{workspace-is-focused}' --json
```

Names retain AeroSpace's order. The current workspace has a stronger label and capsule fill, and is
identified as current to VoiceOver. Long lists scroll horizontally; changing focus reveals the current
name. No buttons or workspace icons are added. A missing CLI, stopped AeroSpace or failed response
shows “AeroSpace unavailable”; a running CLI is retried each second while the palette stays visible.

The provider runs blocking process I/O off-main, cancels an in-flight query when hidden, bounds output
at 64 KiB and terminates a query after two seconds. Executable lookup happens once per visible session.

## Integration and verification

RootPaletteView adds DashboardView as a sibling above its existing header. PaletteWindowController
adds DashboardLayout's height to both panel sizes, keeping the original results space, anchor and
expansion delta. The same height offsets header menus so they still open below the search field.

`dashboard-test` checks JSON decoding, command arguments, failures, output limits, cancellation,
timeouts, scaled geometry and native clock fitting. `palette-placement-test` uses the actual enlarged
panel geometry. Manually check both appearances, compact expansion, search focus, header menus,
workspace focus changes and long workspace names at each Interface Size.
