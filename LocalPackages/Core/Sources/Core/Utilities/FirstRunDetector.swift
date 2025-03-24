//
// FirstRunDetector.swift
// Proton Pass - Created on 24/03/2025.
// Copyright (c) 2025 Proton Technologies AG
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

private let kBundleModificationDate = "BundleModificationDate"
private let kIsFirstRun = "isFirstRun"

// Detect app first run differently on iOS and macOS
// because UserDefaults are not deleted when app is trashed and deleted on macOS
// We rely on bundle's modification date to detect if app is first run on macOS
public protocol FirstRunDetectorProtocol {
    func isFirstRun() -> Bool
    func completeFirstRun()
}

public final class FirstRunDetector: FirstRunDetectorProtocol {
    private let userDefaults: UserDefaults
    private let bundle: Bundle

    public init(userDefaults: UserDefaults, bundle: Bundle) {
        self.userDefaults = userDefaults
        self.bundle = bundle
        userDefaults.register(defaults: [kIsFirstRun: true])
    }
}

public extension FirstRunDetector {
    func isFirstRun() -> Bool {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            let modificationTimestamp = getBundleModificationTimestamp()
            let lastKnownModificationTimestamp = userDefaults.double(forKey: kBundleModificationDate)
            return lastKnownModificationTimestamp == 0 ||
                lastKnownModificationTimestamp != modificationTimestamp
        } else {
            return userDefaults.bool(forKey: kIsFirstRun)
        }
    }

    func completeFirstRun() {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            if let timestamp = getBundleModificationTimestamp() {
                userDefaults.set(timestamp, forKey: kBundleModificationDate)
            }
        } else {
            userDefaults.set(false, forKey: kIsFirstRun)
        }
    }
}

private extension FirstRunDetector {
    func getBundleModificationTimestamp() -> Double? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: bundle.bundlePath)
            if let date = attributes[.modificationDate] as? Date {
                return date.timeIntervalSince1970
            } else {
                return nil
            }
        } catch {
            assertionFailure("Failed to get bundle modification date: \(error)")
            return nil
        }
    }
}
