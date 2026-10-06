import AppKit
import SwiftUI

@main
@MainActor
struct DashboardTests {
    static var failures = 0
    static var passes = 0

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if condition() {
            passes += 1
        } else {
            failures += 1
            print("FAIL: \(message)")
        }
    }

    static func main() async throws {
        geometry()
        clockLayout()
        decoding()
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "tinycast-dashboard-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try await provider(in: directory)
        print("\(passes) passed, \(failures) failed")
        if failures > 0 { exit(1) }
    }

    static func geometry() {
        for size in InterfaceSize.allCases {
            let metrics = size.metrics
            let dashboard = DashboardLayout.height(for: metrics)
            let compact = DashboardLayout.panelHeight(for: metrics, collapsed: true)
            let expanded = DashboardLayout.panelHeight(for: metrics, collapsed: false)
            expect(dashboard == metrics.size.headerHeight + metrics.size.headerPadding * 2,
                   "dashboard composes scaled tokens at \(size)")
            expect(compact - dashboard == metrics.size.compactHeight,
                   "compact search keeps its space at \(size)")
            expect(expanded - dashboard == metrics.size.panelHeight,
                   "results keep their space at \(size)")
            expect(expanded - compact == metrics.size.panelHeight - metrics.size.compactHeight,
                   "expansion still grows only the results at \(size)")
        }
    }

    static func clockLayout() {
        for size in InterfaceSize.allCases {
            let metrics = size.metrics
            let host = NSHostingView(
                rootView: DateClockWidget(isVisible: false).environment(\.metrics, metrics))
            let fitting = host.fittingSize
            expect(fitting.height <= metrics.size.headerHeight,
                   "native clock and date fit the dashboard at \(size)")
            expect(fitting.width > 0 && fitting.width < metrics.size.panelWidth / 2,
                   "clock leaves room for workspace names at \(size)")
        }
    }

    static let workspaceJSON = #"""
        [
          {"workspace":"1","workspace-is-focused":false},
          {"workspace":"Dev \"Swift\"","workspace-is-focused":true},
          {"workspace":"日本語 🚀","workspace-is-focused":false}
        ]
        """#

    static func decoding() {
        do {
            let workspaces = try JSONDecoder().decode(
                [AeroSpaceWorkspace].self, from: Data(workspaceJSON.utf8))
            expect(workspaces.map(\.name) == ["1", "Dev \"Swift\"", "日本語 🚀"],
                   "workspace names and order are preserved verbatim")
            expect(workspaces.filter(\.isFocused).map(\.id) == ["Dev \"Swift\""],
                   "AeroSpace alone identifies the current workspace")
            let empty = try JSONDecoder().decode([AeroSpaceWorkspace].self, from: Data("[]".utf8))
            expect(empty.isEmpty, "empty workspace output is valid")
        } catch {
            expect(false, "valid AeroSpace JSON decodes: \(error)")
        }
        do {
            _ = try JSONDecoder().decode(
                [AeroSpaceWorkspace].self, from: Data(#"[{"workspace":"1"}]"#.utf8))
            expect(false, "missing focus state is rejected")
        } catch {
            expect(true, "missing focus state is rejected")
        }
    }

    static func executable(in directory: URL, name: String, body: String) throws -> URL {
        let url = directory.appending(path: name)
        try ("#!/bin/sh\n" + body + "\n").write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        return url
    }

    static func provider(in directory: URL) async throws {
        let success = try executable(in: directory, name: "success", body: """
            [ "$1" = list-workspaces ] && [ "$2" = --all ] &&
            [ "$3" = --format ] && [ "$4" = '%{workspace}%{workspace-is-focused}' ] &&
            [ "$5" = --json ] || exit 9
            printf '%s\\n' '\(workspaceJSON)'
            """)
        let workspaces = try await AeroSpaceWorkspaceProvider.read(executable: success)
        expect(workspaces.count == 3 && workspaces[1].isFocused,
               "one read-only command supplies names and current state")

        let failure = try executable(in: directory, name: "failure", body: "exit 1")
        await expectFailure(executable: failure, message: "a stopped AeroSpace is unavailable")
        let invalid = try executable(in: directory, name: "invalid", body: "printf 'not JSON'")
        await expectFailure(executable: invalid, message: "malformed output is unavailable")
        await expectFailure(
            executable: directory.appending(path: "missing"), message: "missing CLI is unavailable")
        let oversized = try executable(in: directory, name: "oversized", body: "exec /usr/bin/yes x")
        await expectFailure(executable: oversized, message: "oversized output is bounded")

        let slow = try executable(in: directory, name: "slow", body: "exec /bin/sleep 30")
        let clock = ContinuousClock()
        let start = clock.now
        await expectFailure(executable: slow, message: "a hung CLI is terminated")
        expect(start.duration(to: clock.now) < .seconds(5), "the watchdog bounds a stalled refresh")

        let request = Task { try await AeroSpaceWorkspaceProvider.read(executable: slow) }
        try await Task.sleep(for: .milliseconds(100))
        let cancelledAt = clock.now
        request.cancel()
        do {
            _ = try await request.value
            expect(false, "hiding cancels an in-flight read")
        } catch is CancellationError {
            expect(true, "hiding cancels an in-flight read")
        } catch {
            expect(false, "cancellation reports CancellationError: \(error)")
        }
        expect(cancelledAt.duration(to: clock.now) < .seconds(1),
               "cancellation does not wait for the watchdog")
    }

    static func expectFailure(executable: URL, message: String) async {
        do {
            _ = try await AeroSpaceWorkspaceProvider.read(executable: executable)
            expect(false, message)
        } catch {
            expect(true, message)
        }
    }
}
