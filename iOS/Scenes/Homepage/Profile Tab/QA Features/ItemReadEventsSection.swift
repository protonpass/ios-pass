//
// ItemReadEventsSection.swift
// Proton Pass - Created on 11/06/2024.
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

import DesignSystem
import Entities
import Factory
import SwiftUI

struct ItemReadEventsSection: View {
    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    var enabled: Bool {
        accessRepository.access.value?.access.plan.isBusinessUser == true
    }

    var body: some View {
        NavigationLink(destination: { ItemReadEventsView() },
                       label: {
                           VStack(alignment: .leading) {
                               Text(verbatim: "Item read events")
                               if !enabled {
                                   Text(verbatim: "Only applicable to B2B users")
                                       .font(.caption)
                                       .foregroundStyle(.secondary)
                               }
                           }
                       })
                       .disabled(!enabled)
    }
}

private struct ItemReadEventsView: View {
    @StateObject private var viewModel = ItemReadEventsViewModel()

    var body: some View {
        ZStack {
            if let error = viewModel.error {
                RetryableErrorView(errorMessage: error.localizedDescription,
                                   onRetry: { Task { await viewModel.loadEvents() } })
            } else {
                if viewModel.uiModels.isEmpty {
                    Form {
                        Text(verbatim: "No events")
                            .foregroundStyle(PassColor.textWeak.toColor)
                    }
                } else {
                    eventsList
                }
            }
        }
        .task {
            await viewModel.loadEvents()
        }
    }

    var eventsList: some View {
        Form {
            Section(content: {
                ForEach(viewModel.uiModels) { uiModel in
                    GeneralItemRow(thumbnailView: {
                                       ItemSquircleThumbnail(data: uiModel.uiModel.thumbnailData(),
                                                             pinned: uiModel.uiModel.pinned)
                                   },
                                   title: uiModel.uiModel.title,
                                   description: uiModel.description,
                                   descriptionLineLimit: 2)
                }
            }, header: {
                Text(verbatim: "\(viewModel.uiModels.count) event(s) will be sent along with telemetry events")
            })
        }
    }
}

private struct ItemReadEventsUiModel: Identifiable {
    var id: String { event.uuid }
    let event: ItemReadEvent
    let uiModel: ItemUiModel
    let relativeDate: String

    var description: String {
        if uiModel.description.isEmpty {
            relativeDate
        } else {
            relativeDate + "\n" + uiModel.description
        }
    }

    init(event: ItemReadEvent,
         formatter: RelativeDateTimeFormatter,
         uiModel: ItemUiModel) {
        self.event = event
        self.uiModel = uiModel
        let date = Date(timeIntervalSince1970: event.timestamp)
        relativeDate = formatter.localizedString(for: date, relativeTo: .now)
    }
}

@MainActor
private final class ItemReadEventsViewModel: ObservableObject {
    @Published private(set) var uiModels: [ItemReadEventsUiModel] = []
    @Published private(set) var error: (any Error)?

    private let repository = resolve(\SharedRepositoryContainer.itemReadEventRepository)
    private let appContentManager = resolve(\SharedServiceContainer.appContentManager)
    private let userManager = resolve(\SharedServiceContainer.userManager)

    init() {}

    func loadEvents() async {
        do {
            let userId = try await userManager.getActiveUserId()
            let events = try await repository.getAllEvents(userId: userId).reversed()
            let formatter = RelativeDateTimeFormatter()
            let itemUiModels = appContentManager.getAllSharesItems()
            uiModels = events.compactMap { event -> ItemReadEventsUiModel? in
                if let uiModel = itemUiModels
                    .first(where: { $0.itemId == event.itemId && $0.shareId == event.shareId }) {
                    return .init(event: event,
                                 formatter: formatter,
                                 uiModel: uiModel)
                } else {
                    return nil
                }
            }
        } catch {
            self.error = error
        }
    }
}
