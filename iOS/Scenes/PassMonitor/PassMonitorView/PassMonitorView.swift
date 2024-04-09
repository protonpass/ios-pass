//
//
// PassMonitorView.swift
// Proton Pass - Created on 29/02/2024.
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
//

import DesignSystem
import Entities
import SwiftUI

enum SecureRowType {
    case info, warning, danger, success

    var icon: String? {
        switch self {
        case .danger, .warning:
            "exclamationmark.square.fill"
        case .success:
            "checkmark.square.fill"
        default:
            nil
        }
    }

    var iconColor: UIColor {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMajor1
        case .warning:
            PassColor.noteInteractionNormMajor1
        case .success:
            PassColor.cardInteractionNormMajor1
        default:
            .clear
        }
    }

    var background: UIColor {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMinor2
        case .warning:
            PassColor.noteInteractionNormMinor2
        case .success:
            PassColor.cardInteractionNormMinor2
        case .info:
            PassColor.backgroundNorm
        }
    }

    var border: UIColor {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMinor1
        case .warning:
            PassColor.noteInteractionNormMinor1
        case .success:
            PassColor.cardInteractionNormMinor1
        case .info:
            PassColor.inputBorderNorm
        }
    }

    var infoForeground: UIColor {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMajor2
        case .warning:
            PassColor.noteInteractionNormMajor2
        case .success:
            PassColor.cardInteractionNormMajor2
        case .info:
            PassColor.textNorm
        }
    }

    var infoBackground: UIColor {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMinor1
        case .warning:
            PassColor.noteInteractionNormMinor1
        case .success:
            PassColor.cardInteractionNormMinor1
        case .info:
            PassColor.backgroundMedium
        }
    }
}

struct PassMonitorView: View {
    @StateObject var viewModel: PassMonitorViewModel

    private enum ElementSizes {
        static let cellHeight: CGFloat = 75
    }

    var body: some View {
        mainContent
            .animation(.default, value: viewModel.weaknessStats)
            .navigationTitle("Pass Monitor")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollViewEmbeded(maxWidth: .infinity)
            .background(PassColor.backgroundNorm.toColor)
            .showSpinner(viewModel.loading)
            .sheet(isPresented: $viewModel.showSentinelSheet) {
                SentinelSheetView(isPresented: $viewModel.showSentinelSheet,
                                  sentinelActive: viewModel.isSentinelActive,
                                  mainAction: {
                                      viewModel.sentinelSheetAction()
                                      viewModel.showSentinelSheet = false
                                  }, secondaryAction: { viewModel.showSentinelInformation() })
                    .presentationDetents([.height(570)])
            }
            .navigationStackEmbeded()
            .task {
                await viewModel.refresh()
            }
    }
}

private extension PassMonitorView {
    var mainContent: some View {
        LazyVStack {
            if let weaknessStats = viewModel.weaknessStats {
                breachedDataRows(weaknessStats: weaknessStats)

                sentinelRow(rowType: .info,
                            title: "Proton Sentinel",
                            subTitle: "Advanced account protection program",
                            action: { viewModel.showSentinelSheet = true })
                    .showSpinner(viewModel.updatingSentinel)
                Section {
                    VStack(spacing: DesignConstant.sectionPadding) {
                        weakPasswordsRow(weaknessStats.weakPasswords)
                        reusedPasswordsRow(weaknessStats.reusedPasswords)
                        missing2FARow(weaknessStats.missing2FA)
                            .padding(.top, 16)
                        excludedItemsRow(weaknessStats.excludedItems)
                    }
                } header: {
                    HStack {
                        Text("Passwords Health")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(PassColor.textNorm.toColor)
                        Spacer()
                    }.padding(.top, DesignConstant.sectionPadding)
                }
            }
        }
        .padding(DesignConstant.sectionPadding)
    }
}

private extension PassMonitorView {
    func breachedDataRows(weaknessStats: WeaknessStats) -> some View {
        VStack {
            if viewModel.isFreeUser {
                upsellRow(weaknessStats: weaknessStats)
            } else {
                breachedEmailsRow(weaknessStats.exposedPasswords, showAdvice: true)
                breachedPasswordsRow(weaknessStats.exposedPasswords, showAdvice: true)
            }
        }
    }

    func sentinelRow(rowType: SecureRowType,
                     title: String,
                     subTitle: String?,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(PassColor.textNorm.toColor)
                    if let subTitle {
                        Text(subTitle)
                            .font(.footnote)
                            .foregroundColor(PassColor.textWeak.toColor)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, minHeight: ElementSizes.cellHeight, alignment: .leading)
                .layoutPriority(1)

                StaticToggleView(isOn: viewModel.isSentinelActive)
            }
            .padding(.horizontal, DesignConstant.sectionPadding)
            .roundedDetailSection(backgroundColor: rowType.background,
                                  borderColor: rowType.border)
        }
        .buttonStyle(.plain)
    }

    func upsellRow(weaknessStats: WeaknessStats) -> some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            Text("Data Breach Protection")
                .font(.title)
                .foregroundStyle(PassColor.textNorm.toColor)
                .padding(.top, DesignConstant.sectionPadding)

            VStack(spacing: DesignConstant.sectionPadding / 2) {
                breachedEmailsRow(weaknessStats.exposedPasswords, showAdvice: false)
                breachedPasswordsRow(weaknessStats.exposedPasswords, showAdvice: false)
            }

            Text("Your data appears in data breaches, upgrade to see which ones.")
                .font(.body)
                .foregroundStyle(PassColor.textNorm.toColor)

            CapsuleTextButton(title: "Enable data breach protection",
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNormMajor2,
                              action: {})
                .padding(.bottom, DesignConstant.sectionPadding)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .roundedDetailSection(backgroundColor: SecureRowType.danger.background,
                              borderColor: SecureRowType.danger.border)
    }

    func breachedPasswordsRow(_ breachedPasswords: Int, showAdvice: Bool) -> some View {
        passMonitorRow(rowType: breachedPasswords > 0 ? .warning : .success,
                       title: "Exposed passwords",
                       subTitle: showAdvice ? "Requires immediate action" : nil,
                       info: "\(breachedPasswords)",
                       action: { viewModel.showSecurityWeakness(type: .exposedPassword) })
    }

    func breachedEmailsRow(_ breachedEmails: Int, showAdvice: Bool) -> some View {
        passMonitorRow(rowType: breachedEmails > 0 ? .warning : .success,
                       title: "Exposed emails",
                       subTitle: showAdvice ? "Requires immediate action" : nil,
                       info: "\(breachedEmails)",
                       action: { viewModel.showSecurityWeakness(type: .exposedEmail) })
    }
}

private extension PassMonitorView {
    func weakPasswordsRow(_ weakPasswords: Int) -> some View {
        passMonitorRow(rowType: weakPasswords > 0 ? .warning : .success,
                       title: "Weak Passwords",
                       subTitle: weakPasswords > 0 ? "Create strong passwords" :
                           "you don't have any weak passwords",
                       info: "\(weakPasswords)",
                       action: { viewModel.showSecurityWeakness(type: .weakPasswords) })
    }
}

private extension PassMonitorView {
    func reusedPasswordsRow(_ reusedPasswords: Int) -> some View {
        passMonitorRow(rowType: reusedPasswords > 0 ? .warning : .success,
                       title: "Reused passwords",
                       subTitle: "Create unique passwords",
                       info: "\(reusedPasswords)",
                       action: { viewModel.showSecurityWeakness(type: .reusedPasswords) })
    }
}

private extension PassMonitorView {
    func missing2FARow(_ missing2FA: Int) -> some View {
        passMonitorRow(rowType: missing2FA > 0 ? .warning : .success,
                       title: "Missing two-factor authentication",
                       subTitle: missing2FA > 0 ? "Increase your security" : "You're security is on point",
                       info: "\(missing2FA)",
                       action: { viewModel.showSecurityWeakness(type: .missing2FA) })
    }
}

private extension PassMonitorView {
    func excludedItemsRow(_ excludedItems: Int) -> some View {
        passMonitorRow(rowType: .info,
                       title: "Excluded items",
                       subTitle: "These items remain at risk",
                       info: "\(excludedItems)",
                       action: { viewModel.showSecurityWeakness(type: .excludedItems) })
    }
}

// MARK: - Rows

private extension PassMonitorView {
    func passMonitorRow(rowType: SecureRowType,
                        title: String,
                        subTitle: String?,
                        info: String,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignConstant.sectionPadding) {
                if let iconName = rowType.icon {
                    Image(systemName: iconName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundColor(rowType.iconColor.toColor)
                        .frame(width: DesignConstant.Icons.defaultIconSize)
                }

                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(PassColor.textNorm.toColor)
                    if let subTitle {
                        Text(subTitle)
                            .font(.footnote)
                            .foregroundColor(PassColor.textWeak.toColor)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: ElementSizes.cellHeight, alignment: .leading)
                .contentShape(Rectangle())

                Text(info)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 11)
                    .foregroundColor(rowType.infoForeground.toColor)
                    .background(rowType.infoBackground.toColor)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, DesignConstant.sectionPadding)
            .roundedDetailSection(backgroundColor: rowType.background,
                                  borderColor: rowType.border)
        }
        .buttonStyle(.plain)
    }
}
