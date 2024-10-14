//
// Factory+Extensions.swift
// Proton Pass - Created on 08/07/2023.
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
import Factory
import Foundation

extension FactoryContext {
    /// Overload of `setArg(_:forKey:)`  to make it more flexible
    /// by taking `arg` as `any RawRepresentable<String>` instead of `String`
    static func setArg(_ arg: any RawRepresentable<String>, forKey key: String) {
        setArg(arg.rawValue, forKey: key)
    }

    // periphery:ignore
    /// Overload of `removeArg(forKey:)`  to make it more flexible
    /// by taking `key` as `any RawRepresentable<String>` instead of `String`
    static func removeArg(forKey key: any RawRepresentable<String>) {
        removeArg(forKey: key.rawValue)
    }
}

extension FactoryModifying {
    /// Overload of `onArg(_:factory:)`  to make it more flexible
    /// by taking `arg` as `any RawRepresentable<String>` instead of `String`
    @discardableResult
    func onArg(_ arg: any RawRepresentable<String>, factory: @escaping @Sendable (P) -> T) -> Self {
        onArg(arg.rawValue, factory: factory)
    }
}

extension SharedContainer {
    static func setUpContext() {
        let key = "ProtonPass"
        switch Bundle.main.infoDictionary?["MODULE"] as? String {
        case "AUTOFILL_EXTENSION":
            FactoryContext.setArg(PassModule.autoFillExtension, forKey: key)
        case "SHARE_EXTENSION":
            FactoryContext.setArg(PassModule.shareExtension, forKey: key)
        default:
            // Default to host app
            break
        }
    }
}
