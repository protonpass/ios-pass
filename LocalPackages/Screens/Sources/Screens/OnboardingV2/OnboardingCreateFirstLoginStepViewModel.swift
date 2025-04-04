//
// OnboardingCreateFirstLoginStepViewModel.swift
// Proton Pass - Created on 03/04/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Combine
import Foundation

@MainActor
final class OnboardingCreateFirstLoginStepViewModel: ObservableObject {
    @Published var serviceName = ""
    @Published var selectedService: KnownService? {
        didSet {
            if let selectedService {
                title = selectedService.name
                website = selectedService.url
            }
        }
    }

    @Published private(set) var suggestions = [KnownService]()

    @Published var title = ""
    @Published var email = ""
    @Published var username = ""
    @Published var password = ""
    @Published var website = ""

    var saveable: Bool {
        !title.isEmpty &&
            (!email.isEmpty || !username.isEmpty) &&
            !password.isEmpty
    }

    private var cancellables = Set<AnyCancellable>()
    private let shareId: String
    private let services: [KnownService]
    private let onCreate: (OnboardFirstLoginPayload) -> Void

    init(shareId: String,
         services: [KnownService],
         onCreate: @escaping (OnboardFirstLoginPayload) -> Void) {
        self.shareId = shareId
        self.services = services
        self.onCreate = onCreate

        $serviceName
            .receive(on: DispatchQueue.main)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] name in
                guard let self else { return }
                suggestions = services.filter {
                    $0.name.lowercased().contains(name.lowercased())
                }
                .sorted(by: {
                    // Prioritize matches at the beginning of service's names
                    $0.name.lowercased().hasPrefix(name.lowercased()) &&
                        !$1.name.lowercased().hasPrefix(name.lowercased())
                })
            }
            .store(in: &cancellables)
    }

    func save() {
        guard let selectedService else { return }
        onCreate(.init(shareId: shareId,
                       service: selectedService,
                       title: title,
                       email: email,
                       username: username,
                       password: password,
                       website: website))
    }
}
