import SwiftUI

struct DashboardView: View {
    @Environment(PaletteState.self) private var palette
    @Environment(\.metrics) private var metrics

    var body: some View {
        HStack(spacing: metrics.spacing.xxl) {
            DateClockWidget(isVisible: palette.isVisible)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 0)
            AeroSpaceWorkspacesWidget(isVisible: palette.isVisible)
        }
        .frame(height: metrics.size.headerHeight)
        .padding(.horizontal, metrics.spacing.xxl)
        .padding(.vertical, metrics.size.headerPadding)
        .frame(height: DashboardLayout.height(for: metrics))
    }
}
