import CoreGraphics

enum DashboardLayout {
    static func height(for metrics: InterfaceMetrics) -> CGFloat {
        metrics.size.headerHeight + metrics.size.headerPadding * 2
    }

    static func panelHeight(for metrics: InterfaceMetrics, collapsed: Bool) -> CGFloat {
        (collapsed ? metrics.size.compactHeight : metrics.size.panelHeight) + height(for: metrics)
    }
}
