import Foundation

/// Side-by-side apps with their own bundle ids, so a build updates within its own.
enum ReleaseChannel: Sendable {
    case stable
    case beta
    case homebrew
    /// A local build. It has no release stream, and never updates itself.
    case development

    init(bundleID: String?) {
        switch bundleID {
        case "com.tinycast.app": self = .homebrew
        case "com.tinycast.app.beta": self = .beta
        default: self = .development
        }
    }

    var updatesItself: Bool { self == .stable || self == .beta }

    /// Beta ships as a GitHub prerelease and stable does not; neither ever sees the other's.
    func accepts(prerelease: Bool) -> Bool {
        switch self {
        case .stable: return !prerelease
        case .beta: return prerelease
        case .homebrew, .development: return false
        }
    }
}
