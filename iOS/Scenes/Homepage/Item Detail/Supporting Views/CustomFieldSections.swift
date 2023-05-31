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
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CustomFieldSections: View {
    let itemContent: ItemContent
    let logManager: LogManager

    var body: some View {
        let uiModels = itemContent.customFields.map { CustomFieldUiModel(customField: $0) }
        ForEach(uiModels) { uiModel in
            let customField = uiModel.customField
            let title = customField.title
            let content = customField.content

            let type = itemContent.type
            switch customField.type {
            case .text:
                TextCustomFieldSection(title: title,
                                       content: content,
                                       itemContentType: type)
            case .hidden:
                HiddenCustomFieldSection(title: title,
                                         content: content,
                                         itemContentType: type)
            case .totp:
                TotpCustomFieldSection(title: title,
                                       content: content,
                                       itemContentType: type,
                                       logManager: logManager)
            }
        }
    }
}

struct TextCustomFieldSection: View {
    let title: String
    let content: String
    let itemContentType: ItemContentType

    var body: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: CustomFieldType.text.icon,
                                  color: itemContentType.normColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text(title)
                    .sectionTitleText()
                TextView(.constant(content))
                    .foregroundColor(PassColor.textNorm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(kItemDetailSectionPadding)
        .accentColor(Color(uiColor: itemContentType.normColor)) // Remove when iOS 15 is dropped
        .tint(Color(uiColor: itemContentType.normColor))
        .roundedDetailSection()
        .padding(.top, 8)
    }
}

struct HiddenCustomFieldSection: View {
    @State private var isShowingText = false
    let title: String
    let content: String
    let itemContentType: ItemContentType

    var body: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: CustomFieldType.hidden.icon,
                                  color: itemContentType.normColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                if isShowingText {
                    TextView(.constant(content))
                        .foregroundColor(PassColor.textNorm)
                } else {
                    Text(String(repeating: "•", count: min(20, content.count)))
                        .foregroundColor(Color(uiColor: PassColor.textNorm))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !content.isEmpty {
                CircleButton(icon: isShowingText ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: itemContentType.normMajor2Color,
                             backgroundColor: itemContentType.normMinor2Color,
                             action: { isShowingText.toggle() })
                .fixedSize(horizontal: true, vertical: true)
                .animationsDisabled()
            }
        }
        .animation(.default, value: isShowingText)
        .padding(kItemDetailSectionPadding)
        .accentColor(Color(uiColor: itemContentType.normColor)) // Remove when iOS 15 is dropped
        .tint(Color(uiColor: itemContentType.normColor))
        .roundedDetailSection()
        .padding(.top, 8)
    }
}

struct TotpCustomFieldSection: View {
    @StateObject private var totpManager: TOTPManager
    let title: String
    let content: String
    let itemContentType: ItemContentType

    internal init(title: String,
                  content: String,
                  itemContentType: ItemContentType,
                  logManager: LogManager) {
        self._totpManager = .init(wrappedValue: .init(logManager: logManager))
        self.title = title
        self.content = content
        self.itemContentType = itemContentType
    }

    var body: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: CustomFieldType.totp.icon,
                                  color: itemContentType.normColor)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                switch totpManager.state {
                case .empty:
                    EmptyView()
                case .loading:
                    ProgressView()
                case .valid(let data):
                    TOTPText(code: data.code)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .invalid:
                    Text("Invalid TOTP URI")
                        .font(.caption)
                        .foregroundColor(Color(uiColor: PassColor.signalDanger))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            switch totpManager.state {
            case .valid(let data):
                TOTPCircularTimer(data: data.timerData)
            default:
                EmptyView()
            }
        }
        .padding(kItemDetailSectionPadding)
        .accentColor(Color(uiColor: itemContentType.normColor)) // Remove when iOS 15 is dropped
        .tint(Color(uiColor: itemContentType.normColor))
        .roundedDetailSection()
        .padding(.top, 8)
        .onFirstAppear {
            totpManager.bind(uri: content)
        }
    }
}
