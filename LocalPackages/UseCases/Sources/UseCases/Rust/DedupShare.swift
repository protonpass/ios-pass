//
//
// DedupShare.swift
// Proton Pass - Created on 05/11/2025.
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

import Entities
import PassRustCore

public protocol DedupShareUseCase: Sendable {
    func execute(shares: [Entities.Share]) -> [Entities.Share]
}

public extension DedupShareUseCase {
    func callAsFunction(shares: [Entities.Share]) -> [Entities.Share] {
        execute(shares: shares)
    }
}

public final class DedupShare: DedupShareUseCase {
    private let contentDedupParser: any ShareOverrideCalculatorProtocol

    public init(contentDedupParser: any ShareOverrideCalculatorProtocol = ShareOverrideCalculator()) {
        self.contentDedupParser = contentDedupParser
    }

    public func execute(shares: [Entities.Share]) -> [Entities.Share] {
        let shareIdsToKeep = contentDedupParser.getVisibleShares(shares: shares.map(\.toRustShare))
        return shares.filter { shareIdsToKeep.contains($0.shareId) }
    }
}

private extension Entities.Share {
    var toRustShare: PassRustCore.Share {
        PassRustCore.Share(shareId: shareId,
                           vaultId: vaultID,
                           targetType: shareType.toRustTargetType,
                           targetId: targetID,
                           roleId: shareRoleID,
                           permissions: UInt16(permission))
    }
}

private extension Entities.TargetType {
    var toRustTargetType: PassRustCore.TargetType {
        switch self {
        case .item:
            .item
        case .vault:
            .vault
        default:
            .vault
        }
    }
}
