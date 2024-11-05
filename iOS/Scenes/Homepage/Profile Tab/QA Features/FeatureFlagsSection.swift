//
// FeatureFlagsSection.swift
// Proton Pass - Created on 04/11/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Client
import Core
import DesignSystem
import Foundation
import Observation
import SwiftUI

@available(iOS 17, *)
struct FeatureFlagsSection: View {
    @State private var viewModel = FeatureFlagsSectionModel()

    var body: some View {
        Section {
            ForEach(FeatureFlagType.allCases, id: \.self) { flag in
                row(for: flag.rawValue)
            }
        } header: {
            Text(verbatim: "Feature flags")
        } footer: {
            Text(verbatim: "Activated flags are applied to all accounts")
        }
    }

    private func row(for flag: String) -> some View {
        StaticToggle(LocalizedStringKey(stringLiteral: flag),
                     isOn: viewModel.isActivated(flag),
                     action: { viewModel.toggle(flag) })
    }
}

@available(iOS 17.0, *)
@MainActor @Observable
private final class FeatureFlagsSectionModel {
    private(set) var activatedFlags = Set<String>()

    @ObservationIgnored
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = kSharedUserDefaults) {
        self.userDefaults = userDefaults

        for flag in FeatureFlagType.allCases where userDefaults.bool(forKey: flag.rawValue) {
            activatedFlags.insert(flag.rawValue)
        }
    }

    func isActivated(_ flag: String) -> Bool {
        activatedFlags.contains(flag)
    }

    func toggle(_ flag: String) {
        if activatedFlags.contains(flag) {
            activatedFlags.remove(flag)
            userDefaults.removeObject(forKey: flag)
        } else {
            activatedFlags.insert(flag)
            userDefaults.set(true, forKey: flag)
        }
    }
}
