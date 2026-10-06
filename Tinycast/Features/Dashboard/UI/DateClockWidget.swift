import SwiftUI

struct DateClockWidget: View {
    @Environment(\.metrics) private var metrics
    let isVisible: Bool

    var body: some View {
        Group {
            if isVisible {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    readout(at: context.date)
                }
            } else {
                readout(at: .now)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func readout(at date: Date) -> some View {
        VStack(alignment: .leading, spacing: metrics.spacing.xxs) {
            Text(date, format: .dateTime.hour().minute().second())
                .font(metrics.typography.calcResult)
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(metrics.typography.keyCap)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}
