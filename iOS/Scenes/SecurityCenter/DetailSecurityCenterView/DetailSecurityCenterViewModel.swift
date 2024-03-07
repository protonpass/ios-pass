//
//
// DetailSecurityCenterViewModel.swift
// Proton Pass - Created on 05/03/2024.
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
import Combine
import Entities
import Factory
import Foundation

@MainActor
final class DetailSecurityCenterViewModel: ObservableObject, Sendable {
    @Published private(set) var sectionedData = [SecuritySectionHeaderKey: [ItemContent]]()
    @Published private(set) var showSections = true
    @Published private(set) var loading = true

    let title: String
    let info: String

    private let type: SecurityWeakness
    private let getWeakPasswordLogins = resolve(\UseCasesContainer.getAllWeakPasswordLogins)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)
    private let getAllSecurityAffectedLogins = resolve(\UseCasesContainer.getAllSecurityAffectedLogins)
    private var cancellables = Set<AnyCancellable>()

    init(type: SecurityWeakness) {
        self.type = type
        title = type.title
        info = type.info
        setUp()
    }

    func showDetail(item: ItemContent) {
        router.present(for: .itemDetail(item, showSecurityIssues: true))
    }
}

private extension DetailSecurityCenterViewModel {
    func setUp() {
        getAllSecurityAffectedLogins(for: type)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logins in
                guard let self else {
                    return
                }
                var data = [SecuritySectionHeaderKey: [ItemContent]]()

                for (key, value) in logins {
                    data[key.toSecuritySectionHeaderKey] = value
                }
                sectionedData = data
                loading = false
            }
            .store(in: &cancellables)

//        Task { [weak self] in
//            guard let self else {
//                return
//            }
//            await loadTypeContent()
//        }
    }

//    func loadTypeContent() async {
//        loading = true
//        defer { loading = false }
//
//        switch type {
//        case .weakPasswords:
//            await loadWeakPasswords()
//        case .reusedPasswords:
//            return
//        case .exposedEmail:
//            return
//        case .exposedPassword:
//            return
//        case .missing2FA:
//            return
//        case .excludedItems:
//            return
//        }
//    }
//
//    func loadWeakPasswords() async {
//        do {
//            var data = [SecuritySectionHeaderKey: [ItemContent]]()
//            let symmetricKey = try? symmetricKeyProvider.getSymmetricKey()
//            let weakPasswords = try await getWeakPasswordLogins()
//            for (key, value) in weakPasswords {
//                data[key.toSecuritySectionHeaderKey] = value
//            }
//            sectionedData = data
//        } catch {
//            router.display(element: .displayErrorBanner(error))
//        }
//    }
}

extension PasswordStrength {
    var toSecuritySectionHeaderKey: SecuritySectionHeaderKey {
        SecuritySectionHeaderKey(color: color, title: title, iconName: iconName)
    }
}
