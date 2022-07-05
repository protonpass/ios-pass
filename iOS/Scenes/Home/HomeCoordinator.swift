//
// HomeCoordinator.swift
// Proton Pass - Created on 02/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Core
import SwiftUI
import UIKit

protocol HomeCoordinatorDelegate: AnyObject {
    func homeCoordinatorDidSignOut()
}

final class HomeCoordinator: Coordinator {
    let sessionStorageProvider: SessionStorageProvider
    weak var delegate: HomeCoordinatorDelegate?

    private lazy var homeViewController: UIViewController = {
        let homeView = HomeView(coordinator: self)
        return UIHostingController(rootView: homeView)
    }()

    init(router: Router,
         navigationType: Coordinator.NavigationType,
         sessionStorageProvider: SessionStorageProvider) {
        self.sessionStorageProvider = sessionStorageProvider
        super.init(router: router, navigationType: navigationType)
    }

    override var root: Presentable { homeViewController }

    func signOut() {
        delegate?.homeCoordinatorDidSignOut()
    }
}

extension HomeCoordinator {
    /// For preview purposes
    static var preview: HomeCoordinator {
        .init(router: .init(),
              navigationType: .currentFlow,
              sessionStorageProvider: .preview)
    }
}

struct HomeView: View {
    let coordinator: HomeCoordinator

    var body: some View {
        VStack {
            Text("Welcome to Proton Pass")
            Text(coordinator.sessionStorageProvider.user?.email ?? "")
            Button("Sign out", action: coordinator.signOut)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(coordinator: .preview)
    }
}
