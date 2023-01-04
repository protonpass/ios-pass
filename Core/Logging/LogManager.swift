//
// LogManager.swift
// Proton Pass - Created on 04/01/2023.
// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

import Foundation

enum LogManagerError: Error {
    case failedToSerializeLogEntry
}

public final class LogManager {
    let url: URL
    let queue = DispatchQueue(label: "me.proton.core.log-manager")

    public init(url: URL) {
        self.url = url.appendingPathComponent("proton.log", isDirectory: false)
    }
}

// MARK: - Public APIs
public extension LogManager {
    func log(entry: LogEntry) {
        queue.sync {
            do {
                try createLogFileIfNotExist()
                try pruneLogs()
                try store(entry: entry)
            } catch {
                print("Failed to log: \(error.localizedDescription)")
            }
        }
    }

    func getLogEntries() async throws -> [LogEntry] {
        try await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return [] }
            try self.createLogFileIfNotExist()
            let logContents = try String(contentsOf: self.url, encoding: .utf8)
            let lines = logContents.components(separatedBy: .newlines).filter { !$0.isEmpty }
            let entries = lines.compactMap { line in
                if let data = line.data(using: .utf8) {
                    do {
                        let entry = try JSONDecoder().decode(LogEntry.self, from: data)
                        return entry
                    } catch {
                        print("Corrupted log line: \(line)")
                        return nil
                    }
                } else {
                    return nil
                }
            }
            return entries
        }.value
    }
}

// MARK: - Private APIs
extension LogManager {
    func createLogFileIfNotExist() throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try Data().write(to: url)
        }
    }

    func pruneLogs() throws {
        let maxLogLines = 2_000
        let logContents = try String(contentsOf: url, encoding: .utf8)
        let lines = logContents.components(separatedBy: .newlines)
        if lines.count > maxLogLines {
            let prunedLines = Array(lines.dropFirst(lines.count - maxLogLines))
            let replacementText = prunedLines.joined(separator: "\n")
            try replacementText.data(using: .utf8)?.write(to: url)
        }
    }

    func store(entry: LogEntry) throws {
        let jsonData = try JSONEncoder().encode(entry)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw LogManagerError.failedToSerializeLogEntry
        }
        let dataToLog = Data("\(jsonString)\n".utf8)
        let fileHandle = try FileHandle(forWritingTo: url)
        try fileHandle.seekToEnd()
        try fileHandle.write(contentsOf: dataToLog)
        try fileHandle.close()
    }
}
