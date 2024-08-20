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
    @StateObject var router = resolve(\RouterContainer.darkWebRouter)
    private let addTelemetryEvent = resolve(\SharedUseCasesContainer.addTelemetryEvent)

    var body: some View {
        mainContainer
            .routingProvided
            .sheetDestinations(sheetDestination: $router.presentedSheet)
            .refreshable {
                try? await viewModel.refresh()
            }
            .navigationStackEmbeded($router.path)
            .environmentObject(router)
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
                suggestedEmailsSection
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
    func notMonitoredSection(title: LocalizedStringKey) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text("Monitoring paused")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            ItemDetailSectionIcon(icon: IconProvider.chevronRight,
                                  color: PassColor.textNorm,
                                  width: 15)
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
        if viewModel.access?.monitor.protonAddress == true {
            monitoredProtonAddressesSection
        } else {
            notMonitoredSection(title: "Proton addresses")
                .buttonEmbeded { pushProtonAddressesList() }
        }
    }

    var monitoredProtonAddressesSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            darkWebMonitorHomeRow(title: #localized("Proton addresses"),
                                  subTitle: viewModel.userBreaches.breachedAddresses
                                      .count.breachDescription,
                                  hasBreaches: viewModel.userBreaches.hasBreachedAddresses,
                                  isDetail: false,
                                  action: { pushProtonAddressesList() })
            if viewModel.userBreaches.hasBreachedAddresses {
                PassSectionDivider()
                ForEach(viewModel.userBreaches.topBreachedAddresses) { item in
                    darkWebMonitorHomeRow(title: item.email,
                                          subTitle: "Latest breach on \(item.lastBreachDate ?? "")",
                                          count: item.breachCounter,
                                          hasBreaches: viewModel.userBreaches.hasBreachedAddresses,
                                          isDetail: true,
                                          action: { router.navigate(to: .breachDetail(.protonAddress(item))) })
                }
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
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
                monitoredAliasesSection(infos)
            } else {
                notMonitoredSection(title: title)
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
    }

    @ViewBuilder
    func monitoredAliasesSection(_ infos: [AliasMonitorInfo]) -> some View {
        let breachCount = infos.breachCount
        let hasBreaches = breachCount > 0
        VStack(spacing: DesignConstant.sectionPadding) {
            darkWebMonitorHomeRow(title: #localized("Hide-my-email aliases"),
                                  subTitle: breachCount.breachDescription,
                                  hasBreaches: hasBreaches,
                                  isDetail: false,
                                  action: { pushAliasesList() })
            if hasBreaches {
                PassSectionDivider()
                ForEach(infos.topBreaches) { item in
                    darkWebMonitorHomeRow(title: item.alias.item.aliasEmail ?? "",
                                          subTitle: item.latestBreach,
                                          count: item.breaches?.breaches.allUnresolvedBreaches.count,
                                          hasBreaches: hasBreaches,
                                          isDetail: true,
                                          action: { router.navigate(to: .breachDetail(.alias(item))) })
                }
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }
}

// MARK: - Custom Email sections

private extension DarkWebMonitorHomeView {
    var customEmailsSection: some View {
        Section(content: {
            switch viewModel.customEmailsState {
            case .fetching:
                // Handled in header
                EmptyView()
            case let .fetched(emails):
                ForEach(emails) {
                    customEmailRow(for: $0)
                        .padding(.bottom)
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
        }, header: {
            HStack(spacing: 0) {
                Text("Custom email address")
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
    var suggestedEmailsSection: some View {
        Section(content: {
            switch viewModel.suggestedEmailsState {
            case .fetching:
                EmptyView()
            case let .fetched(emails):
                ForEach(emails, id: \.email) {
                    suggestedEmailRow($0)
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
        }, header: {
            HStack {
                Text("Suggestions")
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(viewModel.suggestedEmailsState.fetchedObject?.isEmpty == true ? 0 : 1)
                Spacer()
                if viewModel.suggestedEmailsState.isFetching || viewModel.updatingStateOfCustomEmail {
                    ProgressView()
                }
            }
        })
    }

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
            CircleButton(icon: IconProvider.chevronDown,
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

private extension Int {
    var breachDescription: String {
        self == 0 ? #localized("No breaches detected") : #localized("Found in %lld breaches", self)
    }
}

private extension [AliasMonitorInfo] {
    var breachCount: Int {
        filter { !$0.alias.item.monitoringDisabled && $0.alias.item.isBreached }.count
    }

    var topBreaches: [AliasMonitorInfo] {
        Array(filter { !$0.alias.item.monitoringDisabled && $0.alias.item.isBreached }
            .sorted { ($0.breaches?.count ?? Int.min) > ($1.breaches?.count ?? Int.min) }
            .prefix(DesignConstant.previewBreachItemCount))
    }
}

private extension [CustomEmail] {
    var breachCount: Int {
        filter { $0.breachCounter > 0 }.count
    }
}
