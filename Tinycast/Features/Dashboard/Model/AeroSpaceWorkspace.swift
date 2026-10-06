import Foundation

struct AeroSpaceWorkspace: Decodable, Equatable, Identifiable, Sendable {
    let name: String
    let isFocused: Bool

    var id: String { name }

    private enum CodingKeys: String, CodingKey {
        case name = "workspace"
        case isFocused = "workspace-is-focused"
    }
}
