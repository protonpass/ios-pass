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
import Combine
import DesignSystem
import Entities
import Factory
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CustomFieldSections: View {
    let itemContentType: ItemContentType
    let uiModels: [CustomFieldUiModel]
    let isFreeUser: Bool
    var isASection = true
    var showIcon = true
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
                                       isASection: isASection,
                                       showIcon: showIcon,
                                       onUpgrade: onUpgrade)
            case .hidden:
                HiddenCustomFieldSection(title: title,
                                         content: content,
                                         itemContentType: itemContentType,
                                         isFreeUser: isFreeUser,
                                         isASection: isASection,
                                         showIcon: showIcon,
                                         onSelect: { onSelectHiddenText(content) },
                                         onUpgrade: onUpgrade)
            case .totp:
                TotpCustomFieldSection(title: title,
                                       content: content,
                                       itemContentType: itemContentType,
                                       isFreeUser: isFreeUser,
                                       isASection: isASection,
                                       showIcon: showIcon,
                                       onSelectTotpToken: onSelectTotpToken,
                                       onUpgrade: onUpgrade)
            case .timestamp:
                // swiftlint:disable:next todo
                // TODO: [Custom item] Implement this
                Text(verbatim: "Timestamp custom field section")
            }

            if uiModel != uiModels.last, !isASection {
                PassSectionDivider()
            }
        }
    }
}

struct TextCustomFieldSection: View {
    let title: String
    let content: String
    let itemContentType: ItemContentType
    let isFreeUser: Bool
    let isASection: Bool
    let showIcon: Bool
    let onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            if showIcon {
                ItemDetailSectionIcon(icon: CustomFieldType.text.icon,
                                      color: itemContentType.normColor)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                if isFreeUser {
                    UpgradeButtonLite(action: onUpgrade)
                } else {
                    TextView(.constant(content))
                        // swiftlint:disable:next deprecated_foregroundcolor_modifier
                        .foregroundColor(PassColor.textNorm)
                        .isEditable(false)
                        .autoDetectDataTypes(.all)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.vertical, isASection ? DesignConstant.sectionPadding : 0)
        .tint(itemContentType.normColor.toColor)
        .if(isASection) { view in
            view.roundedDetailSection()
        }
        .padding(.top, isASection ? 8 : 0)
    }
}

struct HiddenCustomFieldSection: View {
    @State private var isShowingText = false
    let title: String
    let content: String
    let itemContentType: ItemContentType
    let isFreeUser: Bool
    let isASection: Bool
    let showIcon: Bool
    let onSelect: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            if showIcon {
                ItemDetailSectionIcon(icon: CustomFieldType.hidden.icon,
                                      color: itemContentType.normColor)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                if isFreeUser {
                    UpgradeButtonLite(action: onUpgrade)
                } else {
                    if isShowingText {
                        TextView(.constant(content))
                            // swiftlint:disable:next deprecated_foregroundcolor_modifier
                            .foregroundColor(PassColor.textNorm)
                            .isEditable(false)
                    } else {
                        Text(String(repeating: "•", count: min(20, content.count)))
                            .foregroundStyle(PassColor.textNorm.toColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if !isFreeUser {
                    onSelect()
                }
            }

            if !isFreeUser, !content.isEmpty {
                CircleButton(icon: isShowingText ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: itemContentType.normMajor2Color,
                             backgroundColor: itemContentType.normMinor2Color,
                             accessibilityLabel: isShowingText ? "Hide custom field" : "Show custom field",
                             action: { isShowingText.toggle() })
                    .fixedSize(horizontal: true, vertical: true)
                    .animationsDisabled()
            }
        }
        .animation(.default, value: isShowingText)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.vertical, isASection ? DesignConstant.sectionPadding : 0)
        .tint(itemContentType.normColor.toColor)
        .if(isASection) { view in
            view.roundedDetailSection()
        }
        .padding(.top, isASection ? 8 : 0)
    }
}

@MainActor
final class TotpCustomFieldSectionViewModel: ObservableObject {
    @Published private(set) var state = TOTPState.empty

    private let totpManager = resolve(\SharedServiceContainer.totpManager)
    private var cancellable = Set<AnyCancellable>()

    var code: String? {
        totpManager.totpData?.code
    }

    init() {
        totpManager.currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else {
                    return
                }
                state = newState
            }.store(in: &cancellable)
    }

    func bind(uri: String) {
        totpManager.bind(uri: uri)
    }
}

struct TotpCustomFieldSection: View {
    @StateObject private var viewModel = TotpCustomFieldSectionViewModel()
    let title: String
    let content: String
    let itemContentType: ItemContentType
    let isFreeUser: Bool
    let isASection: Bool
    let showIcon: Bool
    let onSelectTotpToken: (String) -> Void
    let onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            if showIcon {
                ItemDetailSectionIcon(icon: CustomFieldType.totp.icon,
                                      color: itemContentType.normColor)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                if isFreeUser {
                    UpgradeButtonLite(action: onUpgrade)
                } else {
                    switch viewModel.state {
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
                            .foregroundStyle(PassColor.signalDanger.toColor)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if !isFreeUser, let code = viewModel.code {
                    onSelectTotpToken(code)
                }
            }

            if !isFreeUser {
                switch viewModel.state {
                case let .valid(data):
                    TOTPCircularTimer(data: data.timerData)
                default:
                    EmptyView()
                }
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.vertical, isASection ? DesignConstant.sectionPadding : 0)
        .tint(itemContentType.normColor.toColor)
        .if(isASection) { view in
            view.roundedDetailSection()
        }
        .padding(.top, isASection ? 8 : 0)
        .onFirstAppear {
            if !isFreeUser {
                viewModel.bind(uri: content)
            }
        }
    }
}
