//
// TelemetryEventsSection.swift
// Proton Pass - Created on 25/04/2023.
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
import SwiftUI
import UIComponents

struct TelemetryEventsSection: View {
    let telemetryEventRepository: TelemetryEventRepositoryProtocol
    let userId: String

    var body: some View {
        Section {
            NavigationLink(destination: {
                let viewModel = TelemetryEventsViewModel(
                    telemetryEventRepository: telemetryEventRepository, userId: userId)
                TelemetryEventsView(viewModel: viewModel)
            }, label: {
                Text("Telemetry events")
            })
        }
    }
}

private struct TelemetryEventUiModel: Identifiable {
    var id: String { event.uuid }
    let event: TelemetryEvent
    let relativeDate: String

    init(event: TelemetryEvent, formatter: RelativeDateTimeFormatter) {
        self.event = event
        self.relativeDate = formatter.localizedString(for: Date(timeIntervalSince1970: event.time),
                                                      relativeTo: .now)
    }
}

private final class TelemetryEventsViewModel: ObservableObject {
    let telemetryEventRepository: TelemetryEventRepositoryProtocol
    let userId: String

    @Published private(set) var uiModels = [TelemetryEventUiModel]()
    @Published private(set) var relativeThreshold = ""
    @Published private(set) var error: Error?

    init(telemetryEventRepository: TelemetryEventRepositoryProtocol, userId: String) {
        self.telemetryEventRepository = telemetryEventRepository
        self.userId = userId
        self.refresh()
    }

    func refresh() {
        Task { @MainActor in
            do {
                let formatter = RelativeDateTimeFormatter()
                if let threshold = telemetryEventRepository.scheduler.threshhold {
                    let relativeDate = formatter.localizedString(for: threshold, relativeTo: .now)
                    self.relativeThreshold = "Next batch \(relativeDate)"
                }
                let events =
                try await telemetryEventRepository.localTelemetryEventDatasource.getAllEvents(userId: userId)
                // Reverse to move new events to the top of the list
                self.uiModels = events.reversed().map { TelemetryEventUiModel(event: $0,
                                                                              formatter: formatter) }
            } catch {
                self.error = error
            }
        }
    }
}

private struct TelemetryEventsView: View {
    @StateObject var viewModel: TelemetryEventsViewModel

    var body: some View {
        if let error = viewModel.error {
            RetryableErrorView(errorMessage: error.localizedDescription, onRetry: viewModel.refresh)
        } else {
            Form {
                ForEach(viewModel.uiModels) { uiModel in
                    EventView(uiModel: uiModel)
                }
            }
            .navigationTitle(viewModel.relativeThreshold)
        }
    }
}

private struct EventView: View {
    let uiModel: TelemetryEventUiModel

    var body: some View {
        let event = uiModel.event

        HStack {
            Label(title: {
                Text(uiModel.event.type.emoji)
                    .foregroundColor(Color(uiColor: PassColor.textNorm))
            }, icon: {
                CircleButton(icon: event.type.itemContentType.icon,
                             iconColor: event.type.itemContentType.normMajor1Color,
                             backgroundColor: event.type.itemContentType.normMinor1Color)
            })

            Spacer()

            Text(uiModel.relativeDate)
                .font(.callout)
                .foregroundColor(Color(uiColor: PassColor.textWeak))
        }
    }
}

private extension TelemetryEventType {
    var itemContentType: ItemContentType {
        switch self {
        case .create(let type):
            return type
        case .read(let type):
            return type
        case .update(let type):
            return type
        case .delete(let type):
            return type
        }
    }

    var emoji: String {
        switch self {
        case .create:
            return "Create ➕"
        case .read:
            return "Read 🗒️"
        case .update:
            return "Update ✏️"
        case .delete:
            return "Delete ❌"
        }
    }
}
