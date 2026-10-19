//
// GetCxpImportSummary.swift
// Proton Pass - Created on 03/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Entities

public protocol GetCxpImportSummaryUseCase: Sendable {
    func callAsFunction(items: [ItemContentProtobuf]) -> [CxpImportSummaryUiModel]
}

public struct GetCxpImportSummary: GetCxpImportSummaryUseCase {
    public init() {}

    public func callAsFunction(items: [ItemContentProtobuf]) -> [CxpImportSummaryUiModel] {
        var totals = [CxpImportSummaryUiModel.Category: Int]()
        for item in items {
            totals[.totp, default: 0] += item.customFields.count { $0.type == .totp }
            switch item.contentData {
            case let .login(data):
                totals[.login, default: 0] += 1
                totals[.passkey, default: 0] += data.passkeys.count
                if !data.totpUri.isEmpty {
                    totals[.totp, default: 0] += 1
                }

            case .note:
                totals[.note, default: 0] += 1

            case .alias:
                totals[.alias, default: 0] += 1

            case .custom, .sshKey, .wifi:
                totals[.custom, default: 0] += 1

            case .identity:
                totals[.identity, default: 0] += 1

            case .creditCard:
                totals[.creditCard, default: 0] += 1
            }
        }

        return CxpImportSummaryUiModel.Category.allCases
            .compactMap { category -> CxpImportSummaryUiModel? in
                guard let total = totals[category], total > 0 else { return nil }
                return .init(category: category, total: total)
            }
            .sorted { lhs, rhs in
                lhs.total == rhs.total ? lhs.category < rhs.category : lhs.total > rhs.total
            }
    }
}
