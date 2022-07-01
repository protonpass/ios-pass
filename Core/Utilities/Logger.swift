//
// Logger.swift
// Proton Key - Created on 29/06/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Key.
//
// Proton Key is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Key is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Key. If not, see https://www.gnu.org/licenses/.

import Foundation
import os.log

public protocol Logger {
    func log(_ error: Error, bundle: Bundle, file: StaticString, function: StaticString, line: UInt)
    func log(_ message: String, bundle: Bundle, file: StaticString, function: StaticString, line: UInt)
}

public final class PKLogger {
    public static let shared = PKLogger()

    private init?() {
        // Only log when in DEBUG mode
        #if DEBUG
        #else
        return nil
        #endif
    }

    private func log(_ message: String, type: OSLogType, osLog: OSLog) {
        // Add a prefix to message to make filtering easy in a jungle of OS logs
        let prefixedMessage = "[\(Self.self)] \(message)"
        os_log("%{public}@", log: osLog, type: type, prefixedMessage)
    }
}

extension PKLogger: Logger {
    public func log(_ error: Error,
                    bundle: Bundle = .main,
                    file: StaticString = #file,
                    function: StaticString = #function,
                    line: UInt = #line) {
        log(String(describing: error), bundle: bundle, file: file, function: function, line: line)
    }

    public func log(_ message: String,
                    bundle: Bundle = .main,
                    file: StaticString = #file,
                    function: StaticString = #function,
                    line: UInt = #line) {
        let category = "\(file) - \(function) - \(line)"
        let osLog = OSLog(subsystem: bundle.bundleIdentifier ?? "", category: category)
        log(message, type: .default, osLog: osLog)
    }
}
