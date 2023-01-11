//
//  PMUnlockViewController.swift
//  ProtonCore-Settings - Created on 27.10.2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_Log
import ProtonCore_UIFoundations

public class PMUnlockViewController: UIViewController {
    lazy var scrollView = KeyboardDismissingScrollView()
    lazy var mainStack = UIStackView(.vertical, alignment: .fill, distribution: .fill, spacing: 20)
    lazy var navigationBar = makeNavigationBar()

    public var viewModel: UnlockViewModel!

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm
        setupNavigationBar()
        setupScrollView()
        addMainStack()
        view.bringSubviewToFront(navigationBar)
        viewModel.onShouldDismissScreen = { [weak self] in
            self?.dismissView()
        }
    }

    @objc private func onAuthenticationSuccess() {
        DispatchQueue.main.async {
            self.dismiss(animated: false, completion: nil)
        }
    }

    @objc private func onLogoutSuccess() {
        DispatchQueue.main.async {
            self.dismiss(animated: false, completion: nil)
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStack.arrangedSubviews.forEach(mainStack.removeArrangedSubview)
        addProtonDriveImage()
        switch viewModel.unlockViewType {
        case .pin:
            addPinProtection()
        case .bio(let biometric):
            addBioProtection(for: biometric)
        case .mix(let biometric):
            addMixProtection(for: biometric)
        case .none:
            viewModel.signOut()
        }
    }

    private func setupNavigationBar() {
        view.addSubview(navigationBar)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 0),
            navigationBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        scrollView.contentInsetAdjustmentBehavior = .never
    }

    private func addMainStack() {
        scrollView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            mainStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 50),
            mainStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -100),
            mainStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            mainStack.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -150),
            mainStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        constraints[4].priority = UILayoutPriority(rawValue: 999)
    }

    private func addProtonDriveImage() {
        let imageView = ProtonHeader()
        let header = viewModel.header
        imageView.setupHeader(image: header.image, subtitle: header.subtitle)
        mainStack.addArrangedSubview(imageView)
    }

    private func addBioProtection(for protection: BiometryType) {
        let bioProtection = BioUnlockContainerView(viewModel: viewModel)
        mainStack.addArrangedSubview(bioProtection)
        viewModel?.unlockWithBio()
    }

    private func addPinProtection() {
        let pinProtectionView = PinUnlockContainerView(pinViewModel: viewModel)
        mainStack.addArrangedSubview(pinProtectionView)
        pinProtectionView.showKeyboard()
    }

    private func addMixProtection(for protection: BiometryType) {
        let mixProtection = MixUnlockContainerView(bioViewModel: viewModel, pinViewModel: viewModel)
        mainStack.addArrangedSubview(mixProtection)
        viewModel?.unlockWithBio()
    }

    private func makeNavigationBar() -> UIView {
        let container = UIView()
        container.backgroundColor = ColorProvider.BackgroundNorm

        let title = UILabel()
        title.font = UIFont.preferredFont(forTextStyle: .headline)
        title.adjustsFontForContentSizeCategory = true
        title.textAlignment = .center
        title.tintColor = ColorProvider.TextNorm
        title.text = "Unlock App"

        container.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            title.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        ])

        if viewModel.allowsSignOut {
            let signOutButton = UIButton()
            signOutButton.setImage(IconProvider.arrowOutFromRectangle, for: .normal)
            signOutButton.addTarget(self, action: #selector(signOutDidTap), for: .touchUpInside)
            signOutButton.tintColor = ColorProvider.TextNorm

            container.addSubview(signOutButton)
            signOutButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                signOutButton.heightAnchor.constraint(equalToConstant: 24),
                signOutButton.widthAnchor.constraint(equalToConstant: 24),
                signOutButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                signOutButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16)
            ])

            NSLayoutConstraint.activate([
                title.leadingAnchor.constraint(lessThanOrEqualTo: signOutButton.trailingAnchor, constant: 30)
            ])
        }

        return container
    }

    private func dismissView() {
        dismiss(animated: false, completion: nil)
    }

    @objc private func signOutDidTap() {
        let alert = UIAlertController(title: "Are you sure?", message: viewModel.alertSubtitle, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            PMLog.debug("Cancel")
        })
        alert.addAction(UIAlertAction(title: "OK", style: .destructive) { [weak self] _ in
            self?.viewModel?.signOut()
            self?.dismiss(animated: true, completion: nil)
        })

        self.present(alert, animated: true, completion: nil)
    }
}

final class KeyboardDismissingScrollView: UIScrollView {
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        endEditing(true)
    }
}
