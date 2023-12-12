//
// ReachabilityService.swift
// Proton Pass - Created on 11/12/2023.
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

@preconcurrency import Combine
import Network

/// Types of network
public enum NerworkType {
    case wifi
    case cellular
    case loopBack
    case wired
    case other
    case unknown
}

/// Protocol containing the current device network states and informations
public protocol ReachabilityServicing: Sendable {
    /// All NWpath informations
    var reachabilityInfos: CurrentValueSubject<NWPath?, Never> { get }
    /// Is network currently available
    var isNetworkAvailable: CurrentValueSubject<Bool, Never> { get }
    /// Type of current connection
    var typeOfCurrentConnection: CurrentValueSubject<NerworkType, Never> { get }
}

/// Helps keep up on the device network state through combine publishers
public final class ReachabilityService: ReachabilityServicing {
    public let reachabilityInfos: CurrentValueSubject<NWPath?, Never> = .init(nil)
    public let isNetworkAvailable: CurrentValueSubject<Bool, Never> = .init(true)
    public let typeOfCurrentConnection: CurrentValueSubject<NerworkType, Never> = .init(.unknown)

    private let monitor: NWPathMonitor
    private let backgroudQueue = DispatchQueue.global(qos: .background)

    public init() {
        monitor = NWPathMonitor()
        setUp()
    }

    public init(with interFaceType: NWInterface.InterfaceType) {
        monitor = NWPathMonitor(requiredInterfaceType: interFaceType)
        setUp()
    }

    deinit {
        monitor.cancel()
    }
}

private extension ReachabilityService {
    func setUp() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else {
                return
            }
            reachabilityInfos.send(path)
            switch path.status {
            case .satisfied:
                isNetworkAvailable.send(true)
            case .requiresConnection, .unsatisfied:
                isNetworkAvailable.send(false)
            @unknown default:
                isNetworkAvailable.send(false)
            }
            if path.usesInterfaceType(.wifi) {
                typeOfCurrentConnection.send(.wifi)
            } else if path.usesInterfaceType(.cellular) {
                typeOfCurrentConnection.send(.cellular)
            } else if path.usesInterfaceType(.loopback) {
                typeOfCurrentConnection.send(.loopBack)
            } else if path.usesInterfaceType(.wiredEthernet) {
                typeOfCurrentConnection.send(.wired)
            } else if path.usesInterfaceType(.other) {
                typeOfCurrentConnection.send(.other)
            } else {
                typeOfCurrentConnection.send(.unknown)
            }
        }

        monitor.start(queue: backgroudQueue)
    }
}
