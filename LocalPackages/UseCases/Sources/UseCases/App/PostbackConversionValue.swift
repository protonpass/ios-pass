//
// PostbackConversionValue.swift
// Proton Pass - Created on 22/12/2025.
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

import AdAttributionKit
import StoreKit

public enum CoarseConversionValue: Sendable {
    case low, medium, high
}

public protocol PostbackConversionValueUseCase: Sendable {
    func execute(_ fineValue: Int,
                 coarseValue: CoarseConversionValue,
                 lockPostback: Bool) async throws
}

public extension PostbackConversionValueUseCase {
    func callAsFunction(_ fineValue: Int,
                        coarseValue: CoarseConversionValue,
                        lockPostback: Bool) async throws {
        try await execute(fineValue, coarseValue: coarseValue, lockPostback: lockPostback)
    }

    /// Non-async variant to use in non async context
    func callAsFunction(_ fineValue: Int,
                        coarseValue: CoarseConversionValue,
                        lockPostback: Bool) {
        Task {
            try? await execute(fineValue, coarseValue: coarseValue, lockPostback: lockPostback)
        }
    }
}

public final class PostbackConversionValue: PostbackConversionValueUseCase {
    public init() {}

    public func execute(_ fineValue: Int,
                        coarseValue: CoarseConversionValue,
                        lockPostback: Bool) async throws {
        // swiftlint:disable:next todo
        // TODO: Use AdAttributionKit instead of StoreKit's SKAdNetwork

        // StoreKit's SKAdNetwork is deprecated but our ad networks
        // haven't fully supported AdAttributionKit so we keep this around
        try await SKAdNetwork.updatePostbackConversionValue(fineValue,
                                                            coarseValue: coarseValue.skAdNetworkValue,
                                                            lockWindow: lockPostback)
        // Enable this after removing StoreKit's SKAdNetwork
//        guard #available(iOS 17.4, *) else { return }
//        try await Postback.updateConversionValue(fineValue,
//                                                 coarseConversionValue: coarseValue.adAttributionKitValue,
//                                                 lockPostback: lockPostback)
    }
}

private extension CoarseConversionValue {
    var skAdNetworkValue: SKAdNetwork.CoarseConversionValue {
        switch self {
        case .low: .low
        case .medium: .medium
        case .high: .high
        }
    }

    // Enable this after removing StoreKit's SKAdNetwork
//    @available(iOS 17.4, *)
//    var adAttributionKitValue: AdAttributionKit.CoarseConversionValue {
//        switch self {
//        case .low: .low
//        case .medium: .medium
//        case .high: .high
//        }
//    }
}
