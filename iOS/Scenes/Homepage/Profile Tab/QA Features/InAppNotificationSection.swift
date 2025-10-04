//
// InAppNotificationSection.swift
// Proton Pass - Created on 14/11/2024.
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

@_spi(QA)
@_spi(QA) import Client
import Combine
import Core
import Entities
import FactoryKit
import SwiftUI

@available(iOS 17, *)
struct InAppNotificationSection: View {
    var body: some View {
        NavigationLink(destination: { InAppNotificationView() },
                       label: { Text(verbatim: "Mock in-app notification") })
    }
}

@available(iOS 17, *)
private struct InAppNotificationView: View {
    @State private var viewModel = InAppNotificationViewModel()

    var body: some View {
        List {
            Section {
                HStack {
                    Text(verbatim: "Last threshold")
                    Spacer()
                    if let lastThreshold = viewModel.lastThreshold {
                        let date = Date(timeIntervalSince1970: lastThreshold)
                        let formatter = RelativeDateTimeFormatter()
                        Text(verbatim: formatter.string(for: date) ?? "N/A")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(verbatim: "N/A")
                            .foregroundStyle(.secondary)
                    }
                }
                Button(action: viewModel.clearThreshold) {
                    Text(verbatim: "Clear last threshold")
                }
            }

            Section(header: Text(verbatim: "In-app notification settings").font(.headline.bold())) {
                TextField(text: $viewModel.notificationKey, prompt: Text(verbatim: "Notification Key")) {
                    Text(verbatim: "Notification Key")
                }
                DatePicker(selection: $viewModel.startDate, displayedComponents: [.date, .hourAndMinute]) {
                    Text(verbatim: "Select a start date")
                }

                Toggle(isOn: $viewModel.addEndTime,
                       label: { Text(verbatim: "Enter end validation date") })

                if viewModel.addEndTime {
                    DatePicker(selection: $viewModel.endDate, displayedComponents: [.date, .hourAndMinute]) {
                        Text(verbatim: "Select a start date")
                    }
                }

                Picker(selection: $viewModel.state,
                       content: {
                           ForEach(InAppNotificationState.allCases, id: \.self) { state in
                               Text(verbatim: state.title)
                                   .tag(state)
                           }
                       }, label: { Text(verbatim: "Notification State") })

                Picker(selection: $viewModel.priority,
                       content: {
                           ForEach(1...30, id: \.self) { prio in
                               Text(verbatim: "\(prio)").tag(prio)
                           }
                       }, label: { Text(verbatim: "Notification priority") })
            }

            Section(header: Text(verbatim: "In-app notification content settings").font(.headline.bold())) {
                TextField(text: $viewModel.imageUrl, prompt: Text(verbatim: "Image url")) {
                    Text(verbatim: "Image url")
                }
                TextField(text: $viewModel.title, prompt: Text(verbatim: "Title")) {
                    Text(verbatim: "Title")
                }
                TextField(text: $viewModel.message, prompt: Text(verbatim: "Message")) {
                    Text(verbatim: "Message")
                }
                Toggle(isOn: $viewModel.addTheme,
                       label: { Text(verbatim: "Add a theme to the notitfication ?") })
                if viewModel.addTheme {
                    TextField(text: $viewModel.theme, prompt: Text(verbatim: "Theme")) {
                        Text(verbatim: "Theme")
                    }
                }

                Picker(selection: $viewModel.displayType,
                       content: {
                           ForEach(InAppNotificationDisplayType.allCases, id: \.self) { type in
                               Text(verbatim: type.title)
                                   .tag(type)
                           }
                       }, label: { Text(verbatim: "Notification display type") })
            }

            Section(header: Text(verbatim: "Notification Cta Settings").font(.headline.bold())) {
                Toggle(isOn: $viewModel.addCta,
                       label: { Text(verbatim: "Add CTA to notification") })
                if viewModel.addCta {
                    TextField(text: $viewModel.text, prompt: Text(verbatim: "CTA text")) {
                        Text(verbatim: "CTA text")
                    }
                    TextField(text: $viewModel.ref, prompt: Text(verbatim: "CTA link(url/deeplink)")) {
                        Text(verbatim: "CTA link(url/deeplink)")
                    }

                    Picker(selection: $viewModel.type,
                           content: {
                               ForEach(QACTAType.allCases, id: \.self) { type in
                                   Text(verbatim: type.rawValue).tag(type)
                               }
                           }, label: { Text(verbatim: "CTA type") })
                }
            }

            Section(content: {
                Toggle(isOn: $viewModel.addPromoContents,
                       label: { Text(verbatim: "Add promo content") })

                if viewModel.addPromoContents {
                    Toggle(isOn: $viewModel.promoContentsStartMinimized,
                           label: { Text(verbatim: "Start minimized") })

                    TextField(text: $viewModel.promoContentsClosePromoText,
                              label: { Text(verbatim: "Close promo text") })

                    TextField(text: $viewModel.promoContentsMinimizedPromoText,
                              label: { Text(verbatim: "Minimize promo text") })

                    TextField(text: $viewModel.promoContentsLightBackgroundImageUrl,
                              label: { Text(verbatim: "Ligh background image URL") })

                    TextField(text: $viewModel.promoContentsLightContentImageUrl,
                              label: { Text(verbatim: "Ligh content image URL") })

                    TextField(text: $viewModel.promoContentsLightContentClosePromoTextColor,
                              label: { Text(verbatim: "Ligh content close promo text color") })

                    TextField(text: $viewModel.promoContentsDarkBackgroundImageUrl,
                              label: { Text(verbatim: "Dark background image URL") })

                    TextField(text: $viewModel.promoContentsDarkContentImageUrl,
                              label: { Text(verbatim: "Dark content image URL") })

                    TextField(text: $viewModel.promoContentsDarkContentClosePromoTextColor,
                              label: { Text(verbatim: "Dark content close promo text color") })
                }
            }, header: {
                Text(verbatim: "Promo contents")
                    .font(.headline.bold())
            }, footer: {
                Text(verbatim: "Only applicable to promo notification type")
            })

            // swiftlint:disable:next line_length
            Text(verbatim: "Adding a mock notification will override the real ones. Don't forget to either kill the app or remove it if you want to test the real ones. To make the mock notification appear just send the app in background and come back to foreground")

            Button { viewModel.sendNotification() } label: {
                Text(verbatim: "Send mock in-app notification")
            }

            Button { viewModel.removeNotification() } label: {
                Text(verbatim: "Remove mock in-app notification")
            }
        }
        .animation(.default, value: viewModel.addCta)
        .animation(.default, value: viewModel.addPromoContents)
        .navigationTitle(Text(verbatim: "Password Policy Settings"))
    }
}

private enum QACTAType: String, CaseIterable {
    case external = "external_link"
    case internalNavigation = "internal_navigation"
}

@available(iOS 17, *)
@MainActor
@Observable
private final class InAppNotificationViewModel {
    @ObservationIgnored
    @LazyInjected(\SharedServiceContainer.inAppNotificationManager)
    private var inAppNotificationManager

    @ObservationIgnored
    @LazyInjected(\SharedRepositoryContainer.localNotificationTimeDatasource)
    private var localNotificationTimeDatasource

    @ObservationIgnored
    @LazyInjected(\SharedServiceContainer.userManager)
    private var userManager

    @ObservationIgnored
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var router

    var lastThreshold: Double?
    var notificationKey = "pass_user_internal_notification"
    var startDate = Date.now
    var addEndTime = false
    var endDate = Date.now
    // Notification state. 0 = Unread, 1 = Read, 2 = Dismissed
    var state: InAppNotificationState = .unread
    var priority: Int = 1

    // MARK: - InAppNotificationContent content

    var imageUrl: String =
        "https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Wikipedia-logo-v2.svg/300px-Wikipedia-logo-v2.svg.png"

    var displayType: InAppNotificationDisplayType = .banner
    var title: String = "Test notification"
    var message: String = "Message of the test notification"
    var addTheme = false

    // Can be light or dark
    var theme: String = ""

    // MARK: - InAppNotificationCTA content

    var addCta = true

    var text: String = "Learn something"
    // Action of the CTA. Can be either external_link | internal_navigation
    var type: QACTAType = .external
    // Destination of the CTA. If type=external_link, it's a URL. If type=internal_navigation, it's a deeplink
    var ref: String = "https://en.wikipedia.org/wiki/Wikipedia"

    var addPromoContents = false
    var promoContentsStartMinimized = false
    var promoContentsClosePromoText = "Don't show this again"
    var promoContentsMinimizedPromoText = "BF promo"
    var promoContentsLightBackgroundImageUrl = "https://picsum.photos/seed/picsum/200/300"
    var promoContentsLightContentImageUrl = "https://picsum.photos/seed/picsum/200/300"
    // swiftlint:disable:next identifier_name
    var promoContentsLightContentClosePromoTextColor = "#000000"
    var promoContentsDarkBackgroundImageUrl = "https://picsum.photos/seed/picsum/200/300"
    var promoContentsDarkContentImageUrl = "https://picsum.photos/seed/picsum/200/300"
    // swiftlint:disable:next identifier_name
    var promoContentsDarkContentClosePromoTextColor = "#FFFFFF"

    init() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                lastThreshold = try await localNotificationTimeDatasource.getNotificationTime(for: userId)
            } catch {
                router.display(element: .errorMessage(error.localizedDescription))
            }
        }
    }

    func clearThreshold() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                try await localNotificationTimeDatasource.removeNotificationTime(for: userId)
                lastThreshold = nil
            } catch {
                router.display(element: .errorMessage(error.localizedDescription))
            }
        }
    }

    func sendNotification() {
        Task {
            var cta: InAppNotificationCTA?
            if addCta {
                cta = InAppNotificationCTA(text: text, type: type.rawValue, ref: ref)
            }

            let lightThemeContents =
                InAppNotificationPromoThemedContents(backgroundImageUrl: promoContentsLightBackgroundImageUrl,
                                                     contentImageUrl: promoContentsLightContentImageUrl,
                                                     closePromoTextColor: promoContentsLightContentClosePromoTextColor)

            let darkThemeContents =
                InAppNotificationPromoThemedContents(backgroundImageUrl: promoContentsDarkBackgroundImageUrl,
                                                     contentImageUrl: promoContentsDarkContentImageUrl,
                                                     closePromoTextColor: promoContentsDarkContentClosePromoTextColor)

            let promoContents =
                InAppNotificationPromoContents(startMinimized: promoContentsStartMinimized,
                                               closePromoText: promoContentsClosePromoText,
                                               minimizedPromoText: promoContentsMinimizedPromoText,
                                               lightThemeContents: lightThemeContents,
                                               darkThemeContents: darkThemeContents)

            let content = InAppNotificationContent(imageUrl: imageUrl,
                                                   displayType: displayType.rawValue,
                                                   title: title,
                                                   message: message,
                                                   theme: theme,
                                                   cta: cta,
                                                   promoContents: promoContents)

            let notification = InAppNotification(ID: UUID().uuidString,
                                                 notificationKey: notificationKey,
                                                 startTime: startDate.timeIntervalSince1970.toInt,
                                                 endTime: addEndTime ? endDate.timeIntervalSince1970.toInt : nil,
                                                 state: state.rawValue,
                                                 priority: priority,
                                                 content: content)
            await inAppNotificationManager.addMockNotification(notification: notification)
        }
    }

    func removeNotification() {
        Task {
            await inAppNotificationManager.removeMockNotification()
        }
    }
}

private extension InAppNotificationDisplayType {
    var title: String {
        switch self {
        case .banner: "Banner"
        case .modal: "Model"
        case .promo: "Promo"
        }
    }
}

private extension InAppNotificationState {
    var title: String {
        switch self {
        case .unread: "Unread"
        case .read: "Read"
        case .dismissed: "Dismissed"
        }
    }
}
