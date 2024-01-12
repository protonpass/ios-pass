//
// CustomFieldSections.swift
// Proton Pass - Created on 31/05/2023.
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

import Client
import Core
import DesignSystem
import Entities
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct CustomFieldSections: View {
    let itemContentType: ItemContentType
    let uiModels: [CustomFieldUiModel]
    let isFreeUser: Bool
    let onSelectHiddenText: (String) -> Void
    let onSelectTotpToken: (String) -> Void
    let onUpgrade: () -> Void

    var body: some View {
        ForEach(uiModels) { uiModel in
            let customField = uiModel.customField
            let title = customField.title
            let content = customField.content

            switch customField.type {
            case .text:
                TextCustomFieldSection(title: title,
                                       content: content,
                                       itemContentType: itemContentType,
                                       isFreeUser: isFreeUser,
                                       onUpgrade: onUpgrade)
            case .hidden:
                HiddenCustomFieldSection(title: title,
                                         content: content,
                                         itemContentType: itemContentType,
                                         isFreeUser: isFreeUser,
                                         onSelect: { onSelectHiddenText(content) },
                                         onUpgrade: onUpgrade)
            case .totp:
                TotpCustomFieldSection(title: title,
                                       content: content,
                                       itemContentType: itemContentType,
                                       isFreeUser: isFreeUser,
                                       onSelectTotpToken: onSelectTotpToken,
                                       onUpgrade: onUpgrade)
            }
        }
    }
}

struct TextCustomFieldSection: View {
    let title: String
    let content: String
    let itemContentType: ItemContentType
    let isFreeUser: Bool
    let onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: CustomFieldType.text.icon,
                                  color: itemContentType.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                if isFreeUser {
                    UpgradeButtonLite(action: onUpgrade)
                } else {
                    TextView(.constant(content))
                        .foregroundColor(PassColor.textNorm)
                        .isEditable(false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignConstant.sectionPadding)
        .tint(itemContentType.normColor.toColor)
        .roundedDetailSection()
        .padding(.top, 8)
    }
}

struct HiddenCustomFieldSection: View {
    @State private var isShowingText = false
    let title: String
    let content: String
    let itemContentType: ItemContentType
    let isFreeUser: Bool
    let onSelect: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: CustomFieldType.hidden.icon,
                                  color: itemContentType.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                if isFreeUser {
                    UpgradeButtonLite(action: onUpgrade)
                } else {
                    if isShowingText {
                        TextView(.constant(content))
                            .foregroundColor(PassColor.textNorm)
                            .isEditable(false)
                    } else {
                        Text(String(repeating: "•", count: min(20, content.count)))
                            .foregroundColor(Color(uiColor: PassColor.textNorm))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isFreeUser {
                    onSelect()
                }
            }

            if !isFreeUser, !content.isEmpty {
                CircleButton(icon: isShowingText ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: itemContentType.normMajor2Color,
                             backgroundColor: itemContentType.normMinor2Color,
                             action: { isShowingText.toggle() })
                    .fixedSize(horizontal: true, vertical: true)
                    .animationsDisabled()
            }
        }
        .animation(.default, value: isShowingText)
        .padding(DesignConstant.sectionPadding)
        .tint(itemContentType.normColor.toColor)
        .roundedDetailSection()
        .padding(.top, 8)
    }
}

struct TotpCustomFieldSection: View {
    @StateObject private var totpManager = resolve(\ServiceContainer.totpManager)
    let title: String
    let content: String
    let itemContentType: ItemContentType
    let isFreeUser: Bool
    let onSelectTotpToken: (String) -> Void
    let onUpgrade: () -> Void

    init(title: String,
         content: String,
         itemContentType: ItemContentType,
         isFreeUser: Bool,
         onSelectTotpToken: @escaping (String) -> Void,
         onUpgrade: @escaping () -> Void) {
        self.title = title
        self.content = content
        self.itemContentType = itemContentType
        self.isFreeUser = isFreeUser
        self.onSelectTotpToken = onSelectTotpToken
        self.onUpgrade = onUpgrade
    }

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: CustomFieldType.totp.icon,
                                  color: itemContentType.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                if isFreeUser {
                    UpgradeButtonLite(action: onUpgrade)
                } else {
                    switch totpManager.state {
                    case .empty:
                        EmptyView()
                    case .loading:
                        ProgressView()
                    case let .valid(data):
                        TOTPText(code: data.code)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    case .invalid:
                        Text("Invalid TOTP URI")
                            .font(.caption)
                            .foregroundColor(Color(uiColor: PassColor.signalDanger))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isFreeUser, let code = totpManager.totpData?.code {
                    onSelectTotpToken(code)
                }
            }

            if !isFreeUser {
                switch totpManager.state {
                case let .valid(data):
                    TOTPCircularTimer(data: data.timerData)
                default:
                    EmptyView()
                }
            }
        }
        .padding(DesignConstant.sectionPadding)
        .tint(itemContentType.normColor.toColor)
        .roundedDetailSection()
        .padding(.top, 8)
        .onFirstAppear {
            if !isFreeUser {
                totpManager.bind(uri: content)
            }
        }
    }
}
