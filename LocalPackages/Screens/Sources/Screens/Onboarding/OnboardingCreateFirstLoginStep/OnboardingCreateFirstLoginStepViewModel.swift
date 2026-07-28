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

import Foundation

@MainActor
@Observable
final class OnboardingCreateFirstLoginStepViewModel {
    var serviceName = ""
    var selectedService: KnownService? {
        didSet {
            if let selectedService {
                title = selectedService.name
                website = selectedService.url
            }
        }
    }

    private(set) var suggestions = [KnownService]()

    var title = ""
    var email = ""
    var username = ""
    var password = ""
    var website = ""

    var saveable: Bool {
        !title.isEmpty &&
            (!email.isEmpty || !username.isEmpty) &&
            !password.isEmpty
    }

    private let shareId: String
    private let services: [KnownService]
    private let onCreate: (OnboardFirstLoginPayload) -> Void

    init(shareId: String,
         services: [KnownService],
         onCreate: @escaping (OnboardFirstLoginPayload) -> Void) {
        self.shareId = shareId
        self.services = services
        self.onCreate = onCreate
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

    func updateSuggestion() async {
        let lowercasedName = serviceName.lowercased()
        suggestions = await Self.match(services, serviceName: lowercasedName)
    }

    @concurrent
    private static func match(_ services: [KnownService],
                              serviceName: String) async -> [KnownService] {
        services.filter {
            $0.name.lowercased().contains(serviceName)
        }
        .sorted(by: {
            // Prioritize matches at the beginning of service's names
            $0.name.lowercased().hasPrefix(serviceName) &&
                !$1.name.lowercased().hasPrefix(serviceName)
        })
    }
}
