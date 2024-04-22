//
//
// DarkWebMonitorHomeView.swift
// Proton Pass - Created on 16/04/2024.
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
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct DarkWebMonitorHomeView: View {
    @StateObject var viewModel: DarkWebMonitorHomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var alertDisplay = false
    var router = resolve(\RouterContainer.darkWebRouter)

    var body: some View {
        mainContainer
    }
}

private extension DarkWebMonitorHomeView {
    var mainContainer: some View {
        VStack {
            Text("Last check: \(viewModel.getCurrentLocalizedDateTime())")
                .foregroundStyle(PassColor.textNorm.toColor)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)

            LazyVStack(spacing: DesignConstant.sectionPadding) {
                addressesSection
                aliasSection
                VStack(spacing: 0) {
                    customEmails
                }
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Dark Web Monitoring")
        .alert(Text("Custom email address"),
               isPresented: $alertDisplay,
               actions: {
                   Button(role: .cancel, label: { Text("OK") })
               },
               message: {
                   // swiftlint:disable:next line_length
                   Text("Monitor email addresses from different domains. You can monitor a maximum of 10 custom addresses.")
               })
    }
}

// MARK: - Proton Addresses

private extension DarkWebMonitorHomeView {
    var addressesSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            darkWebMonitorHomeRow(title: #localized("Proton addresses"),
                                  subTitle: viewModel.breachSubtitle(numberOfBreaches:
                                      viewModel.userBreaches.numberOfBreachedProtonAddresses),
                                  hasBreaches: viewModel.userBreaches.hasBreachedAddresses,
                                  isDetail: false,
                                  action: {})
            if viewModel.userBreaches.hasBreachedAddresses {
                PassSectionDivider()
                ForEach(viewModel.mostBreachedProtonAddress) { item in
                    darkWebMonitorHomeRow(title: item.email,
                                          subTitle: "Latest breach on \(item.lastBreachTime?.lastestBreachDate ?? "")",
                                          info: "\(item.breachCounter)",
                                          hasBreaches: viewModel.userBreaches.hasBreachedAddresses,
                                          isDetail: true,
                                          action: {})
                }
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }
}

// MARK: - Proton Aliases

private extension DarkWebMonitorHomeView {
    var aliasSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            darkWebMonitorHomeRow(title: #localized("Hide-my-email aliases"),
                                  subTitle: viewModel
                                      .breachSubtitle(numberOfBreaches: viewModel.numberOFBreachedAlias),
                                  hasBreaches: !viewModel.noAliasBreaches,
                                  isDetail: false,
                                  action: {})
            if !viewModel.noAliasBreaches {
                PassSectionDivider()
                ForEach(viewModel.mostBreachedAliases) { item in
                    darkWebMonitorHomeRow(title: item.alias.item.aliasEmail ?? "",
                                          subTitle: item.latestBreach,
                                          info: "\(item.breaches?.count ?? 0)",
                                          hasBreaches: !viewModel.noAliasBreaches,
                                          isDetail: true,
                                          action: {})
                }
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }
}

// MARK: - Custom Email sections

private extension DarkWebMonitorHomeView {
    @ViewBuilder
    var customEmails: some View {
        Section(content: {
            if let customEmails = viewModel.customEmails {
                ForEach(customEmails) { item in
                    customEmailRow(for: item)
                        .padding(.vertical, 12)
                }
            }

            if let suggestedEmail = viewModel.suggestedEmail {
                if let customEmails = viewModel.customEmails, !customEmails.isEmpty {
                    Text("Suggestions")
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                }
                ForEach(suggestedEmail, id: \.email) { item in
                    HStack {
                        Image(uiImage: IconProvider.envelope)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 24)
                            .padding(10)
                            .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                            .roundedDetailSection(backgroundColor: PassColor
                                .interactionNormMinor1,
                                borderColor: .clear)
                        Spacer()
                        VStack(alignment: .leading) {
                            Text(item.email)
                                .font(.body)
                                .lineLimit(2)
                                .foregroundStyle(PassColor.textNorm.toColor)
                                .layoutPriority(1)
                                .minimumScaleFactor(0.25)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Used in \(item.count) logins")
                                .font(.footnote)
                                .foregroundStyle(PassColor.textWeak.toColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Spacer()

                        Button {
                            Task {
                                let customEmail = await viewModel.addCustomEmail(email: item.email)
                                router.present(sheet: .addCustomEmail(customEmail: customEmail, isMonitored: true))
                            }
                        } label: {
                            Text("Add")
                                .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 15)
                        }.buttonStyle(.plain)
                            .background(PassColor.interactionNormMinor1.toColor)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 12)
                }
            }
        }, header: {
            HStack {
                Text("Custom email address")
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Button { alertDisplay.toggle() } label: {
                    Image(uiImage: IconProvider.questionCircle)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 16)
                        .padding(10)
                        .foregroundStyle(PassColor.textWeak.toColor)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { router.present(sheet: .addCustomEmail(customEmail: nil, isMonitored: false)) } label: {
                    CircleButton(icon: IconProvider.plus,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Alias action menu")
                }
                .buttonStyle(.plain)
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DesignConstant.sectionPadding)
        })
    }

    @ViewBuilder
    func customEmailRow(for email: CustomEmail) -> some View {
        if email.verified {
            Button {} label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(email.email)
                            .font(.body)
                            .lineLimit(2)
                            .foregroundStyle((email.isBreached ? PassColor
                                    .passwordInteractionNormMajor2 : PassColor.textNorm).toColor)
                            .layoutPriority(1)
                            .minimumScaleFactor(0.25)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(email
                            .isBreached ? "Latest breach on \(email.lastBreachedTime?.lastestBreachDate ?? "")" :
                            "No Breaches detected")
                            .font(.footnote)
                            .foregroundStyle((email.isBreached ? PassColor.textNorm : PassColor
                                    .cardInteractionNormMajor1).toColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()

                    if email.isBreached {
                        Text(verbatim: "\(email.breachCounter)")
                            .font(.body)
                            .fontWeight(.medium)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 11)
                            .foregroundStyle(PassColor.passwordInteractionNormMajor2.toColor)
                            .background(PassColor.passwordInteractionNormMinor1.toColor)
                            .clipShape(Capsule())
                    }

                    Image(uiImage: IconProvider.chevronRight)
                        .resizable()
                        .foregroundStyle((email.isBreached ? PassColor.passwordInteractionNormMajor2 : PassColor
                                .textNorm).toColor)
                        .scaledToFit()
                        .frame(height: 15)
                }
            }
            .buttonStyle(.plain)
        } else {
            HStack {
                Image(uiImage: IconProvider.envelope)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .padding(10)
                    .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                    .roundedDetailSection(backgroundColor: PassColor.interactionNormMinor1,
                                          borderColor: .clear)

                Spacer()
                VStack(alignment: .leading) {
                    Text(email.email)
                        .font(.body)
                        .lineLimit(2)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .layoutPriority(1)
                        .minimumScaleFactor(0.25)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Unverified")
                        .font(.footnote)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()

                Menu(content: {
                    Button { router.present(sheet: .addCustomEmail(customEmail: email, isMonitored: true))
                    } label: {
                        Label(title: { Text("Verify") }, icon: { Image(uiImage: IconProvider.paperPlane) })
                    }

                    Button { viewModel.removeCustomMailFromMonitor(email: email) }
                        label: {
                            Label(title: { Text("Remove") },
                                  icon: { Image(uiImage: IconProvider.trash) })
                        }
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Unverified email action menu")
                })
            }
        }
    }
}

// MARK: - Utils

private extension DarkWebMonitorHomeView {
    func colorOfTitle(hasBreaches: Bool, isDetail: Bool) -> Color {
        if isDetail {
            (hasBreaches ? PassColor.passwordInteractionNormMajor2 : PassColor
                .textNorm).toColor
        } else {
            PassColor.textNorm.toColor
        }
    }

    func colorOfSubtitle(hasBreaches: Bool, isDetail: Bool) -> Color {
        if isDetail {
            PassColor.textNorm.toColor
        } else {
            (hasBreaches ? PassColor.passwordInteractionNormMajor2 : PassColor
                .cardInteractionNormMajor1).toColor
        }
    }

    func darkWebMonitorHomeRow(title: String,
                               subTitle: String?,
                               info: String? = nil,
                               hasBreaches: Bool,
                               isDetail: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignConstant.sectionPadding) {
                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                    Text(title)
                        .font(.body)
                        .lineLimit(1)
                        .foregroundStyle(colorOfTitle(hasBreaches: hasBreaches,
                                                      isDetail: isDetail))
                        .minimumScaleFactor(0.5)

                    if let subTitle {
                        Text(subTitle)
                            .font(.callout)
                            .lineLimit(1)
                            .foregroundStyle(colorOfSubtitle(hasBreaches: hasBreaches, isDetail: isDetail))
                            .layoutPriority(1)
                            .minimumScaleFactor(0.25)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .contentShape(Rectangle())

                if let info {
                    Text(info)
                        .font(.body)
                        .fontWeight(.medium)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 11)
                        .foregroundStyle(PassColor.passwordInteractionNormMajor2.toColor)
                        .background(PassColor.passwordInteractionNormMinor1.toColor)
                        .clipShape(Capsule())
                }

                Image(uiImage: IconProvider.chevronRight)
                    .resizable()
                    .foregroundStyle((hasBreaches ? PassColor.passwordInteractionNormMajor1 : PassColor
                            .textWeak).toColor)
                    .scaledToFit()
                    .frame(height: 15)
            }
            .padding(.horizontal, DesignConstant.sectionPadding)
        }
        .buttonStyle(.plain)
    }
}

private extension DarkWebMonitorHomeView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.loginInteractionNormMajor2,
                         backgroundColor: PassColor.loginInteractionNormMinor1,
                         accessibilityLabel: "Close") {
                dismiss()
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Image(uiImage: viewModel.noBreaches ? IconProvider.checkmarkCircleFilled : IconProvider
                .exclamationCircleFilled)
                .resizable()
                .scaledToFit()
                .foregroundStyle((viewModel.noBreaches ? PassColor.cardInteractionNormMajor2 : PassColor
                        .passwordInteractionNormMajor2).toColor)
                .frame(height: 18)
                .padding(12)
                .background((viewModel.noBreaches ? PassColor.cardInteractionNormMinor2 : PassColor
                        .passwordInteractionNormMinor2).toColor)
                .clipShape(Circle())
        }
    }
}
