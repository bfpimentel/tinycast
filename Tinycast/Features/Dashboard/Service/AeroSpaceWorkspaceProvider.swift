import Foundation

enum AeroSpaceWorkspaceProvider {
    private static let maximumOutputBytes = 64 * 1_024

    enum Failure: Error {
        case unavailable
    }

    nonisolated static func read(executable: URL) async throws -> [AeroSpaceWorkspace] {
        let task = Task.detached {
            try Task.checkCancellation()
            let process = Process()
            let output = Pipe()
            process.executableURL = executable
            process.arguments = [
                "list-workspaces", "--all",
                "--format", "%{workspace}%{workspace-is-focused}", "--json"
            ]
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice
            let exit = try process.runObservingExit()
            defer {
                if process.isRunning { process.terminate() }
                exit.wait()
                try? output.fileHandleForReading.close()
            }
            return try await withTaskCancellationHandler {
                let watchdog = Task {
                    do {
                        try await Task.sleep(for: .seconds(2))
                    } catch {
                        return
                    }
                    if process.isRunning { process.terminate() }
                }
                defer { watchdog.cancel() }
                var data = Data()
                while data.count < maximumOutputBytes {
                    let remaining = maximumOutputBytes - data.count
                    guard let chunk = try output.fileHandleForReading.read(upToCount: remaining),
                        !chunk.isEmpty
                    else { break }
                    data.append(chunk)
                }
                if data.count == maximumOutputBytes, process.isRunning { process.terminate() }
                exit.wait()
                try Task.checkCancellation()
                guard process.terminationStatus == 0, data.count < maximumOutputBytes else {
                    throw Failure.unavailable
                }
                return try JSONDecoder().decode([AeroSpaceWorkspace].self, from: data)
            } onCancel: {
                if process.isRunning { process.terminate() }
            }
        }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }
}
