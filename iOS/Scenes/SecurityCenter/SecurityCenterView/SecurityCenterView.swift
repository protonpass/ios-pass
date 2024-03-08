//
//
// SecurityCenterView.swift
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

import Client
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

    var iconColor: Color {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMajor1.toColor
        case .warning:
            PassColor.noteInteractionNormMajor1.toColor
        case .success:
            PassColor.cardInteractionNormMajor1.toColor
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

    var infoForeground: Color {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMajor2.toColor
        case .warning:
            PassColor.noteInteractionNormMajor2.toColor
        case .success:
            PassColor.cardInteractionNormMajor2.toColor
        case .info:
            PassColor.textNorm.toColor
        }
    }

    var infoBackground: Color {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMinor1.toColor
        case .warning:
            PassColor.noteInteractionNormMinor1.toColor
        case .success:
            PassColor.cardInteractionNormMinor1.toColor
        case .info:
            PassColor.backgroundMedium.toColor
        }
    }
}

struct SecurityCenterView: View {
    @StateObject var viewModel: SecurityCenterViewModel

    private enum ElementSizes {
        static let cellHeight: CGFloat = 75
    }

    var body: some View {
        mainContent
            .animation(.default, value: viewModel.weaknessStats)
            .navigationTitle("Security Center")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollViewEmbeded(maxWidth: .infinity)
            .background(PassColor.backgroundNorm.toColor)
            .showSpinner(viewModel.loading)
            .navigationStackEmbeded()
            .task {
                await viewModel.refresh()
            }
    }
}

private extension SecurityCenterView {
    var mainContent: some View {
        LazyVStack {
            if let weaknessStats = viewModel.weaknessStats {
                breachedDataRows(weaknessStats: weaknessStats)
                weakPasswordsRow(weaknessStats.weakPasswords)
                reusedPasswordsRow(weaknessStats.reusedPasswords)
                missing2FARow(weaknessStats.missing2FA)
                excludedItemsRow(weaknessStats.excludedItems)
                Spacer(minLength: 24)
                lastUpdateInfo(date: viewModel.lastUpdate)
            }
        }
        .padding(DesignConstant.sectionPadding)
    }
}

private extension SecurityCenterView {
    @ViewBuilder
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

    @ViewBuilder
    func breachedPasswordsRow(_ breachedPasswords: Int, showAdvice: Bool) -> some View {
        securityCenterRow(rowType: breachedPasswords > 0 ? .warning : .success,
                          title: "Exposed passwords",
                          subTitle: showAdvice ? "Requires immediate action" : nil,
                          info: "\(breachedPasswords)",
                          action: { viewModel.showSecurityWeakness(type: .exposedPassword) })
    }

    @ViewBuilder
    func breachedEmailsRow(_ breachedEmails: Int, showAdvice: Bool) -> some View {
        securityCenterRow(rowType: breachedEmails > 0 ? .warning : .success,
                          title: "Exposed emails",
                          subTitle: showAdvice ? "Requires immediate action" : nil,
                          info: "\(breachedEmails)",
                          action: { viewModel.showSecurityWeakness(type: .exposedEmail) })
    }
}

private extension SecurityCenterView {
    @ViewBuilder
    func weakPasswordsRow(_ weakPasswords: Int) -> some View {
        securityCenterRow(rowType: weakPasswords > 0 ? .warning : .success,
                          title: "Weak Passwords",
                          subTitle: weakPasswords > 0 ? "Create strong passwords" :
                              "you don't have any weak passwords",
                          info: "\(weakPasswords)",
                          action: { viewModel.showSecurityWeakness(type: .weakPasswords) })
    }
}

private extension SecurityCenterView {
    @ViewBuilder
    func reusedPasswordsRow(_ reusedPasswords: Int) -> some View {
        securityCenterRow(rowType: reusedPasswords > 0 ? .warning : .success,
                          title: "Reused passwords",
                          subTitle: "Create unique passwords",
                          info: "\(reusedPasswords)",
                          action: { viewModel.showSecurityWeakness(type: .reusedPasswords) })
    }
}

private extension SecurityCenterView {
    @ViewBuilder
    func missing2FARow(_ missing2FA: Int) -> some View {
        securityCenterRow(rowType: missing2FA > 0 ? .warning : .success,
                          title: "Missing two-factor authentication",
                          subTitle: missing2FA > 0 ? "Increase your security" : "You're security is on point",
                          info: "\(missing2FA)",
                          action: { viewModel.showSecurityWeakness(type: .missing2FA) })
    }
}

private extension SecurityCenterView {
    @ViewBuilder
    func excludedItemsRow(_ excludedItems: Int) -> some View {
        securityCenterRow(rowType: .info,
                          title: "Excluded items",
                          subTitle: "These items remain at risk",
                          info: "\(excludedItems)",
                          action: { viewModel.showSecurityWeakness(type: .excludedItems) })
    }
}

private extension SecurityCenterView {
    @ViewBuilder
    func lastUpdateInfo(date: String?) -> some View {
        VStack {
            if let date {
                Text("Last Data Breach Protection Sync:")
                Text(date)
            }
        }.font(.caption)
            .foregroundStyle(PassColor.textWeak.toColor)
    }
}

// MARK: - Rows

private extension SecurityCenterView {
    func securityCenterRow(rowType: SecureRowType,
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
                        .foregroundColor(rowType.iconColor)
                        .frame(width: 20)
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
                    .foregroundColor(rowType.infoForeground)
                    .background(rowType.infoBackground)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, DesignConstant.sectionPadding)
            .roundedDetailSection(backgroundColor: rowType.background,
                                  borderColor: rowType.border)
        }
        .buttonStyle(.plain)
    }
}
