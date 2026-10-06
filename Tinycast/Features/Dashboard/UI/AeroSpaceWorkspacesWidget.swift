import SwiftUI

struct AeroSpaceWorkspacesWidget: View {
    @Environment(\.metrics) private var metrics
    @State private var workspaces: [AeroSpaceWorkspace]?
    let isVisible: Bool

    var body: some View {
        Group {
            if let workspaces, !workspaces.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                        HStack(spacing: metrics.spacing.xs) {
                            ForEach(workspaces) { workspace in
                                Text(workspace.name)
                                    .font(metrics.typography.rowTrailing)
                                    .fontWeight(workspace.isFocused ? .semibold : .regular)
                                    .foregroundStyle(
                                        workspace.isFocused
                                            ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                                    .padding(.horizontal, metrics.spacing.md)
                                    .padding(.vertical, metrics.spacing.sm)
                                    .background(
                                        workspace.isFocused ? Theme.Colors.selection : .clear,
                                        in: Capsule())
                                    .accessibilityLabel(
                                        workspace.isFocused
                                            ? "\(workspace.name), current workspace" : workspace.name)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .defaultScrollAnchor(.trailing, for: .alignment)
                    .onChange(of: workspaces.first(where: \.isFocused)?.id, initial: true) {
                        if let current = workspaces.first(where: \.isFocused) {
                            proxy.scrollTo(current.id, anchor: .center)
                        }
                    }
                }
            } else {
                Text("AeroSpace unavailable")
                    .font(metrics.typography.keyCap)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("AeroSpace workspaces")
        .task(id: isVisible) {
            workspaces = nil
            guard isVisible, let executable = await ExecutableLocator.locate("aerospace") else {
                return
            }
            while !Task.isCancelled {
                do {
                    let latest = try await AeroSpaceWorkspaceProvider.read(executable: executable)
                    try Task.checkCancellation()
                    if workspaces != latest { workspaces = latest }
                } catch {
                    guard !Task.isCancelled else { return }
                    workspaces = nil
                }
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }
        }
    }
}
