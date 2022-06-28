//
// AppCoordinator.swift
// Proton Key - Created on 21/06/2022.
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
import Core
import UIKit

class AppCoordinator: Coordinator, ObservableObject {
    private let appStateObserver: AppStateObserver

    override var root: Presentable { router.toPresentable() }

    init(appStateObserver: AppStateObserver, router: Router) {
        self.appStateObserver = appStateObserver
        super.init(router: router, navigationType: .newFlow(hideBar: true))

        bindAppState()
        bindDeeplink()
    }

    private func bindAppState() {
        appStateObserver.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] appState in
                self?.refreshRoot(appState: appState)
            }.store(in: &cancellables)
    }

    private func refreshRoot(appState: AppState) {
        switch appState {
        case .loggedOut:
            setUpLoginFlow()
        case .loggedIn:
            setUpHomeFlow()
        @unknown default:
            fatalError("Should not happen")
        }
    }

    private func bindDeeplink() {
        deeplinkSubject
            .unwrap()
            .map(AppFlow.init(deeplink:))
            .unwrap()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deeplink in
                guard let self = self else { return }
                switch deeplink {
                case .logIn:
                    self.setUpLoginFlow()
                case .home:
                    self.setUpHomeFlow()
                }
                self.resetDeeplink()
            }.store(in: &cancellables)
    }

    private func setUpLoginFlow() {
        let logInCoordinator = LogInCoordinator(
            router: router,
            navigationType: .newFlow(hideBar: true),
            appStateObserver: appStateObserver
        )
        setRootChild(coordinator: logInCoordinator, hideBar: true)
    }

    private func setUpHomeFlow() {
        let homeCoordinator = HomeCoordinator(router: router,
                                              navigationType: .newFlow(hideBar: true),
                                              appStateObserver: appStateObserver)
        setRootChild(coordinator: homeCoordinator, hideBar: true)
    }
}
