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

import Entities
import Foundation

// sourcery: AutoMockable
public protocol LogManagerProtocol: Actor {
    // periphery:ignore
    var shouldLog: Bool { get }

    func log(entry: LogEntry)
    func getLogEntries() async throws -> [LogEntry]
    // periphery:ignore
    func removeAllLogs()
    func saveAllLogs()
    // periphery:ignore
    func toggleLogging(shouldLog: Bool)

    // periphery:ignore
    @_spi(Test) func getLogEntriesWithoutSave() throws -> [LogEntry]
}

public struct LogManagerConfig: Sendable {
    let maxLogLines: Int
    let dumpThreshold: Int
    let timerInterval: Double

    public init(maxLogLines: Int, dumpThreshold: Int = 50, timerInterval: Double = 30) {
        self.maxLogLines = maxLogLines
        self.dumpThreshold = dumpThreshold
        self.timerInterval = timerInterval
    }

    public static var `default`: LogManagerConfig {
        LogManagerConfig(maxLogLines: 5_000, dumpThreshold: 300, timerInterval: 30)
    }
}

public actor LogManager: LogManagerProtocol {
    /// `nil` ⇒ degraded mode (App Group container unavailable). All operations are no-ops.
    private let url: URL?
    private let config: LogManagerConfig
    private let clock: any Clock<Duration>

    private var isSetUp = false
    private var fileExists = false
    private var currentSavedLogs = [String]()
    private var currentMemoryLogs = [LogEntry]()
    private var timerTask: Task<Void, Never>?

    public private(set) var shouldLog: Bool

    public init(module: PassModule,
                containerProvider: (String) -> URL? = {
                    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0)
                }) {
        let container = containerProvider(Constants.appGroup)
        assert(container != nil,
               "App Group container unavailable — check the \(Constants.appGroup) entitlement for this target.")
        self.init(url: container, fileName: module.logFileName)
    }

    /// Manage (read/write) the log file on disk.
    /// - Parameters:
    ///   - folderURL: The folder containing the log file. `nil` creates a disabled manager.
    ///   - fileName: The name of the log file, e.g. "proton.log".
    ///   - config: Configurations.
    ///   - clock: Injectable for deterministic timer tests.
    public init(url folderURL: URL?,
                fileName: String,
                config: LogManagerConfig = .default,
                clock: any Clock<Duration> = ContinuousClock()) {
        if let folderURL {
            url = folderURL.appendingPathComponent(fileName, isDirectory: false)
            shouldLog = true
        } else {
            url = nil
            shouldLog = false
        }
        self.config = config
        self.clock = clock
    }

    deinit {
        timerTask?.cancel()
    }
}

// MARK: - Public APIs

public extension LogManager {
    func log(entry: LogEntry) {
        guard shouldLog else { return }
        ensureSetUp()
        currentMemoryLogs.append(entry)
        if currentMemoryLogs.count >= config.dumpThreshold {
            saveAllLogs()
        }
    }

    /// Sorted so the in-app log viewer and exported/shared log files are always chronological,
    /// including across the dump batches `mergeAndClear` can only order individually.
    func getLogEntries() throws -> [LogEntry] {
        saveAllLogs()
        guard let url, fileExists else { return [] }
        let contents = try String(contentsOf: url, encoding: .utf8)
        return contents
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { String($0).toLogEntry }
            .sorted { $0.timestamp < $1.timestamp }
    }

    func removeAllLogs() {
        currentSavedLogs.removeAll()
        currentMemoryLogs.removeAll()
        guard let url, fileExists else { return }
        do {
            try FileManager.default.removeItem(at: url)
            fileExists = false
        } catch {
            print("Failed to remove log file: \(error.localizedDescription)")
        }
    }

    func saveAllLogs() {
        guard shouldLog, let url else { return }
        ensureSetUp()
        guard !currentMemoryLogs.isEmpty else { return }
        mergeAndClear()
        pruneIfNeeded()
        do {
            try writeToDisk(at: url)
        } catch {
            print("Failed to persist logs: \(error.localizedDescription)")
        }
    }

    func toggleLogging(shouldLog: Bool) {
        if !shouldLog {
            saveAllLogs()
        }
        self.shouldLog = shouldLog
    }
}

@_spi(Test) public extension LogManager {
    /// Deliberately unsorted, unlike `getLogEntries()`: this returns the file verbatim so tests
    /// can assert the on-disk order that `mergeAndClear` is responsible for.
    func getLogEntriesWithoutSave() throws -> [LogEntry] {
        guard let url, fileExists else { return [] }
        let contents = try String(contentsOf: url, encoding: .utf8)
        return contents
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { String($0).toLogEntry }
    }
}

// MARK: - Private APIs

private extension LogManager {
    func ensureSetUp() {
        guard !isSetUp, let url else { return }
        isSetUp = true
        fileExists = FileManager.default.fileExists(atPath: url.path)
        if fileExists, let contents = try? String(contentsOf: url, encoding: .utf8) {
            currentSavedLogs = contents
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map(String.init)
        }
        startTimer()
    }

    /// Merge first, then prune: overflow can never exceed the merged count,
    /// so `removeFirst` is trap-free by construction.
    ///
    /// Sorted on merge because `Logger.log(entry:)` dispatches every entry in its own
    /// unstructured `Task`: this actor serialises execution but not arrival, so entries land
    /// here in arbitrary order. Their timestamps are stamped at the call site and are accurate
    /// — only the arrival order is not, which is why sorting recovers the true order.
    // ponytail: orders within a dump batch. An entry delayed past a flush still lands a few
    // positions late. Upgrade path is ordered ingestion — have `Logger.log` yield into an
    // AsyncStream drained by one task, instead of a Task per entry.
    func mergeAndClear() {
        currentSavedLogs.append(contentsOf: currentMemoryLogs
            .sorted { $0.timestamp < $1.timestamp }
            .compactMap(\.toString))
        currentMemoryLogs.removeAll()
    }

    func pruneIfNeeded() {
        let overflow = currentSavedLogs.count - config.maxLogLines
        if overflow > 0 {
            currentSavedLogs.removeFirst(overflow)
        }
    }

    func writeToDisk(at url: URL) throws {
        let data = Data(currentSavedLogs.joined(separator: "\n").utf8)
        try data.write(to: url, options: .atomic)
        fileExists = true
    }

    func startTimer() {
        guard timerTask == nil else { return }
        let interval = Duration.seconds(config.timerInterval)
        timerTask = Task { [weak self, clock] in
            while !Task.isCancelled {
                try? await clock.sleep(for: interval)
                guard !Task.isCancelled, let self else { return }
                await flushPendingLogs()
            }
        }
    }

    func flushPendingLogs() {
        guard shouldLog, !currentMemoryLogs.isEmpty else { return }
        saveAllLogs()
    }
}

// MARK: - Utils Extensions

private extension LogEntry {
    var toString: String? {
        guard let jsonData = try? JSONEncoder().encode(self) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
}

private extension String {
    var toLogEntry: LogEntry? {
        guard let data = data(using: .utf8),
              let entry = try? JSONDecoder().decode(LogEntry.self, from: data) else {
            return nil
        }
        return entry
    }
}
