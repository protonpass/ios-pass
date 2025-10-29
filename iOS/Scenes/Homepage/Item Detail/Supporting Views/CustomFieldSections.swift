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
import Core
import DesignSystem
import Entities
import FactoryKit
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct CustomFieldSections: View {
    let itemContentType: ItemContentType
    let fields: [CustomField]
    let isFreeUser: Bool
    var isASection = true
    var showIcon = true
    let onSelectHiddenText: (String) -> Void
    let onSelectTotpToken: (String) -> Void
    let onUpgrade: () -> Void

    var body: some View {
        ForEach(fields) { field in
            let title = field.title
            let content = field.content

            switch field.type {
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
                TimestampCustomFieldSection(title: title,
                                            content: content,
                                            itemContentType: itemContentType,
                                            isFreeUser: isFreeUser,
                                            isASection: isASection,
                                            showIcon: showIcon,
                                            onUpgrade: onUpgrade)
            }

            if field != fields.last, !isASection {
                PassSectionDivider()
            }
        }
    }
}

private struct TextCustomFieldSection: View {
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
                    UpgradeButtonLite(foregroundColor: itemContentType.normMajor2Color,
                                      action: onUpgrade)
                } else if content.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    ReadOnlyTextView(content)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.vertical, isASection ? DesignConstant.sectionPadding : 0)
        .tint(itemContentType.normColor)
        .if(isASection) { view in
            view.roundedDetailSection()
        }
        .padding(.top, isASection ? 8 : 0)
    }
}

private struct HiddenCustomFieldSection: View {
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
                    UpgradeButtonLite(foregroundColor: itemContentType.normMajor2Color,
                                      action: onUpgrade)
                } else {
                    if content.isEmpty {
                        Text("Empty")
                            .placeholderText()
                    } else {
                        ReadOnlyTextView(isShowingText ?
                            content : String(repeating: "•", count: min(20, content.count)))
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
        .tint(itemContentType.normColor)
        .if(isASection) { view in
            view.roundedDetailSection()
        }
        .padding(.top, isASection ? 8 : 0)
    }
}

@MainActor
private final class TotpCustomFieldSectionViewModel: ObservableObject {
    @Published private(set) var state = TOTPState.empty

    private let totpService = resolve(\SharedServiceContainer.totpService)
    private let logManager = resolve(\SharedToolingContainer.logManager)
    private var cancellable = Set<AnyCancellable>()

    // Manually construct an instance of TOTPManager instead of getting via Factory
    // to make sure each custom field has its own uniqe manager that binds to its respective URI
    // `TOTPManager` is scoped as `unique` but Factory somehow still gives the same instance
    // for all TOTP custom fields (could be Factory bug as of version 2.5.1)
    private lazy var totpManager = TOTPManager(logManager: logManager,
                                               totpService: totpService)

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

private struct TotpCustomFieldSection: View {
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
                    UpgradeButtonLite(foregroundColor: itemContentType.normMajor2Color,
                                      action: onUpgrade)
                } else {
                    switch viewModel.state {
                    case .empty:
                        Text("Empty")
                            .placeholderText()
                    case .loading:
                        ProgressView()
                    case let .valid(data):
                        TOTPText(code: data.code)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    case .invalid:
                        Text("Invalid TOTP URI")
                            .font(.caption)
                            .foregroundStyle(PassColor.signalDanger)
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
        .tint(itemContentType.normColor)
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

private struct TimestampCustomFieldSection: View {
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
                ItemDetailSectionIcon(icon: CustomFieldType.timestamp.icon,
                                      color: itemContentType.normColor)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                if isFreeUser {
                    UpgradeButtonLite(foregroundColor: itemContentType.normMajor2Color,
                                      action: onUpgrade)
                } else if content.isEmpty {
                    Text("Empty")
                        .italic()
                        .foregroundStyle(PassColor.textWeak)
                } else if let timeInterval = TimeInterval(content) {
                    let date = Date(timeIntervalSince1970: timeInterval)
                    Text(verbatim: DateFormatter.timestampCustomField.string(from: date))
                        .foregroundStyle(PassColor.textNorm)
                } else {
                    Text("Error occurred")
                        .font(.caption)
                        .foregroundStyle(PassColor.signalDanger)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.vertical, isASection ? DesignConstant.sectionPadding : 0)
        .tint(itemContentType.normColor)
        .if(isASection) { view in
            view.roundedDetailSection()
        }
        .padding(.top, isASection ? 8 : 0)
    }
}
