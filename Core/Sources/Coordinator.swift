//
// Coordinator.swift
// Proton Key - Created on 20/06/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Key.
//
// Proton Key is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Key is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Key. If not, see https://www.gnu.org/licenses/.

import Combine
import UIKit

/// Coordinator is the protocol every coordinator conforms to.
open class Coordinator: NSObject {
    public enum NavigationType {
        /// Push is considered on current flow
        case currentFlow

        /// Present  or set root for new flow
        case newFlow(hideBar: Bool) // present, set root
    }

    private let router: Router
    private var childCoordinators: [Coordinator] = []
    private let navigationType: NavigationType
    private var cancellables = Set<AnyCancellable>()
    private let deeplinkSubject = CurrentValueSubject<String?, Never>(nil)
    private var deeplinkCancellables = Set<AnyCancellable>()

    open var root: Presentable { fatalError("To be overridden")}

    // MARK: - Initialization
    public init(router: Router, navigationType: NavigationType) {
        self.router = router
        self.navigationType = navigationType

        super.init()

        if case .newFlow(let hideBar) = navigationType {
            router.setRoot(root, hideBar: hideBar)
        }
    }

    // MARK: - Reset deeplink
    public func resetDeeplink() {
        for child in childCoordinators {
            child.deeplinkCancellables = Set<AnyCancellable>()
        }
        deeplinkSubject.send(nil)
    }

    // MARK: - Child coordinator
    public func addChild(_ coordinator: Coordinator) {
        deeplinkSubject
            .subscribe(coordinator.deeplinkSubject)
            .store(in: &coordinator.deeplinkCancellables)

        childCoordinators.append(coordinator)
    }

    private func removeChild(_ coordinator: Coordinator) {
        if let index = childCoordinators.firstIndex(of: coordinator) {
            childCoordinators.remove(at: index)
        }
    }

    public func setRootChild(coordinator: Coordinator, hideBar: Bool) {
        addChild(coordinator)
        router.setRoot(coordinator, hideBar: hideBar) { [weak self, weak coordinator] in
            guard let coord = coordinator else { return }
            self?.removeChild(coord)
        }
    }

    public func pushChild(coordinator: Coordinator, animated: Bool, onRemove: (() -> Void)? = nil) {
        addChild(coordinator)
        router.push(coordinator, animated: animated) { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else { return }
            onRemove?()
            self.removeChild(coordinator)
        }
    }

    /// - Important: Make sure to always call dismissChild after
    public func presentChild(coordinator: Coordinator, animated: Bool) {
        addChild(coordinator)
        router.present(coordinator, animated: animated)
    }

    public func dismissChild(_ coordinator: Coordinator, animated: Bool) {
        coordinator.toPresentable().presentingViewController?.dismiss(animated: animated, completion: nil)
        removeChild(coordinator)
    }
}

// MARK: - Presentable protocol
extension Coordinator: Presentable {
    public func toPresentable() -> UIViewController {
        switch navigationType {
        case .currentFlow:
            return root.toPresentable()
        case .newFlow:
            return router.toPresentable()
        }
    }
}
