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
import DesignSystem
import Entities
import Factory
import SwiftUI

struct InAppNotificationSection: View {
    var body: some View {
        NavigationLink(destination: { InAppNotificationView() },
                       label: { Text(verbatim: "Mock In app notification") })
    }
}

private struct InAppNotificationView: View {
    @StateObject private var viewModel = InAppNotificationViewModel()

    var body: some View {
        List {
            Section(header: Text(verbatim: "In app notification Settings").font(.headline.bold())) {
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
                           ForEach(QANotificationState.allCases, id: \.self) { state in
                               Text(verbatim: state.rawValue).tag(state)
                           }
                       }, label: { Text(verbatim: "Notification State") })

                Picker(selection: $viewModel.priority,
                       content: {
                           ForEach(1...30, id: \.self) { prio in
                               Text(verbatim: "\(prio)").tag(prio)
                           }
                       }, label: { Text(verbatim: "Notification priority") })
            }

            Section(header: Text(verbatim: "In app notification content Settings").font(.headline.bold())) {
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
                           ForEach(QADisplayType.allCases, id: \.self) { type in
                               Text(verbatim: type.rawValue).tag(type)
                           }
                       }, label: { Text(verbatim: "Notification display type") })
            }

            Section(header: Text(verbatim: "Notification Cta Settings").font(.headline.bold())) {
                Toggle(isOn: $viewModel.addCta,
                       label: { Text(verbatim: "Add Cta to notification") })
                if viewModel.addCta {
                    TextField(text: $viewModel.text, prompt: Text(verbatim: "Cta text")) {
                        Text(verbatim: "Cta text")
                    }
                    TextField(text: $viewModel.ref, prompt: Text(verbatim: "Cta link(url/deeplink)")) {
                        Text(verbatim: "Cta link(url/deeplink)")
                    }

                    Picker(selection: $viewModel.type,
                           content: {
                               ForEach(QACTAType.allCases, id: \.self) { type in
                                   Text(verbatim: type.rawValue).tag(type)
                               }
                           }, label: { Text(verbatim: "Cta type") })
                }
            }

            // swiftlint:disable:next line_length
            Text(verbatim: "Adding a mock notification will override the real ones. Don't forget to either kill the app or remove it if you want to test the real ones. To make the mock notification appear just send the app in background and come back to foreground")

            Button { viewModel.sendNotification() } label: {
                Text(verbatim: "Send mock in app notification")
            }

            Button { viewModel.removeNotification() } label: {
                Text(verbatim: "Remove mock in app notification")
            }
        }
        .animation(.default, value: viewModel.addCta)
        .navigationTitle(Text(verbatim: "Password Policy Settings"))
    }
}

private enum QACTAType: String, CaseIterable {
    case external = "external_link"
    case internalNavigation = "internal_navigation"
}

private enum QANotificationState: String, CaseIterable {
    case unread
    case read
    case dismissed

    var value: Int {
        switch self {
        case .unread: 0
        case .read: 1
        case .dismissed: 2
        }
    }
}

private enum QADisplayType: String, CaseIterable {
    case modal
    case banner

    var value: Int {
        switch self {
        case .banner: 0
        case .modal: 1
        }
    }
}

@MainActor
private final class InAppNotificationViewModel: ObservableObject {
    @LazyInjected(\SharedServiceContainer.inAppNotificationManager) var inAppNotificationManager

    @Published var notificationKey = "pass_user_internal_notification"
    @Published var startDate = Date.now
    @Published var addEndTime = false
    @Published var endDate = Date.now
    // Notification state. 0 = Unread, 1 = Read, 2 = Dismissed
    @Published var state: QANotificationState = .unread
    @Published var priority: Int = 1

    // MARK: - InAppNotificationContent content

    @Published var imageUrl: String =
        "https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Wikipedia-logo-v2.svg/300px-Wikipedia-logo-v2.svg.png"
    //    0 = Banner, 1 = Modal.
    //    Banner -> The small bar on the bottom
    //    Modal -> Full screen in your face
    @Published var displayType: QADisplayType = .banner
    @Published var title: String = "Test notification"
    @Published var message: String = "Message of the test notification"
    @Published var addTheme = false

    // Can be light or dark
    @Published var theme: String = ""

    // MARK: - InAppNotificationCTA content

    @Published var addCta = true

    @Published var text: String = "Learn something"
    // Action of the CTA. Can be either external_link | internal_navigation
    @Published var type: QACTAType = .external
    // Destination of the CTA. If type=external_link, it's a URL. If type=internal_navigation, it's a deeplink
    @Published var ref: String = "https://en.wikipedia.org/wiki/Wikipedia"

    init() {}

    func sendNotification() {
        Task {
            var cta: InAppNotificationCTA?
            if addCta {
                cta = InAppNotificationCTA(text: text, type: type.rawValue, ref: ref)
            }
            let content = InAppNotificationContent(imageUrl: imageUrl,
                                                   displayType: displayType.value,
                                                   title: title,
                                                   message: message,
                                                   theme: theme,
                                                   cta: cta)
            let notification = InAppNotification(ID: UUID().uuidString,
                                                 notificationKey: notificationKey,
                                                 startTime: startDate.timeIntervalSince1970.toInt,
                                                 endTime: addEndTime ? endDate.timeIntervalSince1970.toInt : nil,
                                                 state: state.value,
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
