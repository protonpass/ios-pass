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
import Screens
import SwiftUI

struct DarkWebMonitorHomeView: View {
    @StateObject var viewModel: DarkWebMonitorHomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDataSecurityExplanation = false
    @State private var showNoBreachesAlert = false
    @State private var showBreachesFoundAlert = false
    @EnvironmentObject private var router: PathRouter
    private let addTelemetryEvent = resolve(\SharedUseCasesContainer.addTelemetryEvent)

    var body: some View {
        mainContainer
            .refreshable {
                try? await viewModel.refresh()
            }
    }
}

private extension DarkWebMonitorHomeView {
    var mainContainer: some View {
        VStack {
            mainTitle
                .padding(.top)
            VStack(spacing: DesignConstant.sectionPadding) {
                protonAddressesSection
                aliasesSection
                customEmailsSection
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.aliasBreachesState)
        .animation(.default, value: viewModel.customEmailsState)
        .animation(.default, value: viewModel.suggestedEmailsState)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(PassColor.backgroundNorm.toColor,
                           for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .alert(Text("Data Security"),
               isPresented: $showDataSecurityExplanation,
               actions: { Button("OK", action: {}) },
               message: {
                   // swiftlint:disable:next line_length
                   Text("Proton never shares your information with third parties. All data comes from searches for the appearance of Proton domains on the dark web.")
               })
        .alert(Text(verbatim: "✅"),
               isPresented: $showNoBreachesAlert,
               actions: { Button("OK", action: {}) },
               message: { Text("None of your email addresses or aliases appear in a data breach") })
        .alert(Text(verbatim: "⚠️"),
               isPresented: $showBreachesFoundAlert,
               actions: { Button("OK", action: {}) },
               message: { Text("One of your email addresses or aliases appear in a data breach") })
    }

    var mainTitle: some View {
        Label(title: {
            Text("Dark Web Monitoring")
                .font(.title.bold())
                .foregroundStyle(PassColor.textNorm.toColor)
        }, icon: {
            Button(action: {
                showDataSecurityExplanation = true
            }, label: {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: 24)
            })
            .buttonStyle(.plain)
        })
        .labelStyle(.rightIcon)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension DarkWebMonitorHomeView {
    func emptySection(title: LocalizedStringKey,
                      subtitle: LocalizedStringKey,
                      iconDisplay: Bool) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if iconDisplay {
                ItemDetailSectionIcon(icon: IconProvider.chevronRight,
                                      color: PassColor.textNorm,
                                      width: 15)
            }
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
        .contentShape(.rect)
    }
}

// MARK: - Proton Addresses

private extension DarkWebMonitorHomeView {
    @ViewBuilder
    var protonAddressesSection: some View {
        Section(content: {
            if viewModel.access?.monitor.protonAddress == true {
                monitoredProtonAddressesSection
            } else {
                emptySection(title: "Proton addresses",
                             subtitle: "Monitoring paused",
                             iconDisplay: true)
                    .buttonEmbeded { pushProtonAddressesList() }
            }
        }, header: {
            HStack(spacing: 0) {
                let title = viewModel.userBreaches.addresses
                    .isEmpty ? #localized("Proton addresses") :
                    #localized("Proton addresses") + " " + "(\(viewModel.userBreaches.addresses.count))"

                Text(title)
                    .monitorSectionTitleText(maxWidth: nil)

                Spacer()

                if viewModel.access?.monitor.protonAddress == true,
                   !viewModel.userBreaches.addresses.isEmpty {
                    Button {
                        pushProtonAddressesList()
                    } label: {
                        Text("See all")
                            .font(.callout.weight(.bold))
                            .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                            .padding(.trailing, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DesignConstant.sectionPadding)
        })
    }

    var monitoredProtonAddressesSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            ForEach(viewModel.userBreaches.topBreachedAddresses) { item in
                darkWebMonitorHomeRow(title: item.email,
                                      subTitle: item
                                          .breached ? "Latest breach on \(item.lastBreachDate ?? "")" :
                                          "No breaches detected",
                                      count: item.breached ? item.breachCounter : nil,
                                      hasBreaches: item.breached,
                                      isDetail: false,
                                      action: { router.navigate(to: .breachDetail(.protonAddress(item))) })
                if item != viewModel.userBreaches.topBreachedAddresses.last {
                    PassDivider()
                }
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedEditableSection()
    }

    func pushProtonAddressesList() {
        router.navigate(to: .protonAddressesList(viewModel.userBreaches.addresses))
        addTelemetryEvent(with: .monitorDisplayMonitoringProtonAddresses)
    }

    func pushAliasesList() {
        if let infos = viewModel.aliasBreachesState.fetchedObject, !infos.isEmpty {
            router.navigate(to: .aliasesList(infos))
            addTelemetryEvent(with: .monitorDisplayMonitoringEmailAliases)
        }
    }
}

// MARK: - Aliases

private extension DarkWebMonitorHomeView {
    @ViewBuilder
    var aliasesSection: some View {
        Section(content: {
            let title: LocalizedStringKey = "Hide-my-email aliases"
            switch viewModel.aliasBreachesState {
            case .fetching:
                HStack {
                    VStack(alignment: .leading) {
                        Text(title)
                            .foregroundStyle(PassColor.textNorm.toColor)
                        Text(verbatim: "You can't see me, can you?")
                            .redacted(reason: .placeholder)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    ProgressView()
                }
                .padding(DesignConstant.sectionPadding)
                .roundedDetailSection()

            case let .fetched(infos):
                if viewModel.access?.monitor.aliases == true {
                    if infos.isEmpty {
                        emptySection(title: title,
                                     subtitle: "No aliases",
                                     iconDisplay: false)
                    } else {
                        monitoredAliasesSection(infos)
                    }
                } else {
                    emptySection(title: title,
                                 subtitle: "Monitoring paused",
                                 iconDisplay: true)
                        .buttonEmbeded { pushAliasesList() }
                }

            case let .error(error):
                HStack {
                    Text(error.localizedDescription)
                        .font(.callout)
                        .foregroundStyle(PassColor.passwordInteractionNormMajor2.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    RetryButton { viewModel.fetchAliasBreaches() }
                }
                .padding(DesignConstant.sectionPadding)
                .roundedDetailSection()
                .frame(minHeight: 50)
            }
        }, header: {
            HStack(spacing: 0) {
                let title = if let number = viewModel.aliasBreachesState.numberDisplay {
                    #localized("Hide-my-email aliases") + " " + number
                } else {
                    #localized("Hide-my-email aliases")
                }

                Text(title)
                    .monitorSectionTitleText(maxWidth: nil)

                Spacer()

                if viewModel.access?.monitor.aliases == true,
                   case let .fetched(data) = viewModel.aliasBreachesState, !data.isEmpty {
                    Button {
                        pushAliasesList()
                    } label: {
                        Text("See all")
                            .font(.callout.weight(.bold))
                            .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                            .padding(.trailing, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DesignConstant.sectionPadding)
        })
    }

    @ViewBuilder
    func monitoredAliasesSection(_ infos: [AliasMonitorInfo]) -> some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            ForEach(infos.topBreaches) { item in
                let unresolvedBreaches = item.breachCounter > 0
                darkWebMonitorHomeRow(title: item.email,
                                      subTitle: unresolvedBreaches ? item
                                          .latestBreach : "No breaches detected",
                                      count: unresolvedBreaches ? item.breachCounter : nil,
                                      hasBreaches: unresolvedBreaches,
                                      isDetail: false,
                                      action: { router.navigate(to: .breachDetail(.alias(item))) })
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedEditableSection()
    }
}

// MARK: - Custom Email sections

private extension DarkWebMonitorHomeView {
    var customEmailsSection: some View {
        Section(content: {
            VStack(spacing: 10) {
                switch viewModel.customEmailsState {
                case .fetching:
                    // Handled in header
                    EmptyView()
                case let .fetched(emails):
                    ForEach(emails) { email in
                        customEmailRow(for: email)
                        if email != emails.last {
                            PassDivider()
                        }
                    }
                case let .error(error):
                    HStack {
                        Text(error.localizedDescription)
                            .font(.callout)
                            .foregroundStyle(PassColor.passwordInteractionNormMajor2.toColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        RetryButton { viewModel.fetchCustomEmails() }
                    }
                }

                if case let .fetched(data) = viewModel.customEmailsState, !data.isEmpty,
                   case let .fetched(data) = viewModel.suggestedEmailsState, !data.isEmpty {
                    PassDivider()
                }

                switch viewModel.suggestedEmailsState {
                case .fetching:
                    EmptyView()
                case let .fetched(emails):
                    ForEach(emails, id: \.email) { email in
                        suggestedEmailRow(email)

                        if email != emails.last {
                            PassDivider()
                        }
                    }
                case let .error(error):
                    HStack {
                        Text(error.localizedDescription)
                            .font(.callout)
                            .foregroundStyle(PassColor.passwordInteractionNormMajor2.toColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        RetryButton { viewModel.fetchSuggestedEmails() }
                    }
                }
            }
            .padding(DesignConstant.sectionPadding)
            .roundedEditableSection()
        }, header: {
            HStack(spacing: 0) {
                let title = if let number = viewModel.customEmailsState.numberDisplay {
                    #localized("Custom email address") + " " + number
                } else {
                    #localized("Custom email address")
                }

                Text(title)
                    .monitorSectionTitleText(maxWidth: nil)

                Spacer()

                switch viewModel.customEmailsState {
                case .fetching:
                    ProgressView()
                case .fetched:
                    CircleButton(icon: IconProvider.plus,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Add custom email address",
                                 type: .small,
                                 action: { router.present(sheet: .addCustomEmail(nil)) })
                case .error:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DesignConstant.sectionPadding)
        })
    }

    @ViewBuilder
    func customEmailRow(for email: CustomEmail) -> some View {
        if email.verified {
            MonitorIncludedEmailView(address: email,
                                     action: { router.navigate(to: .breachDetail(.customEmail(email))) })
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
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Unverified")
                        .font(.footnote)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()

                Menu(content: {
                    Label(title: { Text("Verify") },
                          icon: { Image(uiImage: IconProvider.paperPlane) })
                        .buttonEmbeded { router.present(sheet: .addCustomEmail(email)) }

                    Label(title: { Text("Remove") },
                          icon: { Image(uiImage: IconProvider.trash) })
                        .buttonEmbeded { viewModel.removeCustomMailFromMonitor(email: email) }
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: PassColor.textWeak,
                                 backgroundColor: .clear,
                                 accessibilityLabel: "Unverified email action menu")
                })
            }
        }
    }
}

// MARK: Suggested emails section

private extension DarkWebMonitorHomeView {
    func suggestedEmailRow(_ email: SuggestedEmail) -> some View {
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
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Used in \(email.count) logins")
                    .font(.footnote)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            CapsuleTextButton(title: #localized("Add"),
                              titleColor: PassColor.interactionNormMajor2,
                              backgroundColor: PassColor.interactionNormMinor1) {
                Task {
                    if let customEmail = await viewModel.addCustomEmail(email: email.email) {
                        router.present(sheet: .addCustomEmail(customEmail))
                        addTelemetryEvent(with: .monitorAddCustomEmailFromSuggestion)
                    }
                }
            }
            .fixedSize(horizontal: true, vertical: true)
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
                               count: Int? = nil,
                               hasBreaches: Bool,
                               isDetail: Bool,
                               action: @escaping () -> Void) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .foregroundStyle(colorOfTitle(hasBreaches: hasBreaches, isDetail: isDetail))

                if let subTitle {
                    Text(subTitle)
                        .font(.callout)
                        .foregroundStyle(colorOfSubtitle(hasBreaches: hasBreaches, isDetail: isDetail))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let count {
                CapsuleCounter(count: count,
                               foregroundStyle: SecureRowType.danger.iconColor.toColor,
                               background: SecureRowType.danger.background.toColor)
            }

            ItemDetailSectionIcon(icon: IconProvider.chevronRight,
                                  color: hasBreaches ?
                                      PassColor.passwordInteractionNormMajor1 : PassColor.textWeak,
                                  width: 15)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contentShape(.rect)
        .buttonEmbeded(action: action)
    }
}

private extension DarkWebMonitorHomeView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        if let aliasBreaches = viewModel.aliasBreachesState.fetchedObject,
           let customEmailBreaches = viewModel.customEmailsState.fetchedObject {
            let totalBreaches = aliasBreaches.breachCount + customEmailBreaches.breachCount + viewModel
                .userBreaches.emailsCount
            let noBreaches = totalBreaches == 0
            let icon: UIImage = noBreaches ? IconProvider.checkmarkCircleFilled : IconProvider
                .exclamationCircleFilled
            let iconColor = noBreaches ? PassColor.cardInteractionNormMajor2 : PassColor
                .passwordInteractionNormMajor2
            let backgroundColor = noBreaches ? PassColor.cardInteractionNormMinor2 : PassColor
                .passwordInteractionNormMinor2
            ToolbarItem(placement: .navigationBarTrailing) {
                CircleButton(icon: icon, iconColor: iconColor, backgroundColor: backgroundColor) {
                    if noBreaches {
                        showNoBreachesAlert.toggle()
                    } else {
                        showBreachesFoundAlert.toggle()
                    }
                }
            }
        }
    }
}

private extension [AliasMonitorInfo] {
    var breachCount: Int {
        filter { !$0.alias.item.monitoringDisabled && $0.alias.item.isBreached }.count
    }

    var topBreaches: [AliasMonitorInfo] {
        Array(filter { !$0.alias.item.monitoringDisabled }
            .sorted {
                (($0.breaches?.count ?? Int.min), $0.alias.item.revisionTime, $1.email) >
                    (($1.breaches?.count ?? Int.min),
                     $0.alias.item
                         .revisionTime,
                     $0.email)
            }
            .prefix(DesignConstant.previewBreachItemCount))
    }
}

private extension [CustomEmail] {
    var breachCount: Int {
        filter { $0.breachCounter > 0 }.count
    }
}

private extension FetchableObject where T: Collection, T.Element: Equatable {
    var numberDisplay: String? {
        if case let .fetched(data) = self, !data.isEmpty {
            return "(\(data.count))"
        }
        return nil
    }
}
