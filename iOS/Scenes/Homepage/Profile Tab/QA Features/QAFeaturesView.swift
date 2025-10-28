//
// QAFeaturesView.swift
// Proton Pass - Created on 15/04/2023.
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

import Core
import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

struct QAFeaturesView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(Constants.QA.forceDisplayUpgradeAppBanner)
    private var displayUpgradeAppBanner = false

    @AppStorage(Constants.QA.searchAndListSecureLink)
    private var searchAndListSecureLink = false

    @AppStorage(Constants.QA.useSwiftUIList, store: kSharedUserDefaults)
    private var useSwiftUIList = false

    var body: some View {
        NavigationStack {
            Form {
                OnboardSection()
                if #available(iOS 17, *) {
                    FeatureFlagsSection()
                }
                HapticFeedbacksSection()
                Section {
                    AccountSwitcherSection()
                    CredentialsSection()
                    CachedFavIconsSection()
                    TelemetryEventsSection()
                    ItemReadEventsSection()
                    TrashItemsSection()
                    BannersSection()
                    PasswordPolicySection()
                    FeatureDiscoverySection()
                    DismissibleUIElementsSection()

                    if #available(iOS 17, *) {
                        NewLoginSection()
                        InAppNotificationSection(onDismiss: dismiss.callAsFunction)
                    }
                    Toggle(isOn: $displayUpgradeAppBanner) {
                        Text(verbatim: "Display upgrade app banner")
                    }

                    Toggle(isOn: $searchAndListSecureLink) {
                        Text(verbatim: "Display search secure link")
                    }

                    Toggle(isOn: $useSwiftUIList) {
                        Text(verbatim: "Use SwiftUI List")
                        // swiftlint:disable line_length
                        Text(verbatim: """
                        We keep 2 implementations of list (SwiftUI List and UIKit UITableView)
                        because of SwiftUI List performance issues which specifically arise on iOS 18
                        This option allows to do the switch on the fly in order to benchmark SwiftUI List in future iOS versions
                        """)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        // swiftlint:enable line_length
                    }
                }

                FileAttachmentViewerSection()

                if #available(iOS 17, *) {
                    AliasDiscoverySection()
                    TipKitSection()
                }
            }
            .navigationTitle(Text(verbatim: "QA Features"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Close",
                                 action: dismiss.callAsFunction)
                }
            }
        }
        .tint(PassColor.interactionNorm)
    }
}
