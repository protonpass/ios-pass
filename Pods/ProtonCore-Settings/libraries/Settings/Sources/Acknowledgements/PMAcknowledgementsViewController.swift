//
//  PMAcknowledgementsViewController.swift
//  ProtonCore-Settings - Created on 09.11.2020.
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

import ProtonCore_UIFoundations

final class PMAcknowledgementsViewModel {
    let url: URL
    let title: String?

    init(title: String?, url: URL) {
        self.url = url
        self.title = title
    }

    func load() -> NSAttributedString? {
        if let acknowledgements = try? String(contentsOfFile: url.path) {
            return parser(markdown: acknowledgements)
        } else {
            return nil
        }
    }

    func parser(markdown: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for line in markdown.components(separatedBy: "\n") {
            if line.hasPrefix("###") {
                let string = line.replacingOccurrences(of: "###", with: "")
                result.append(attributed(of: string, with: UIFont.preferredFont(forTextStyle: .title3)))
            } else if line.hasPrefix("##") {
                let string = line.replacingOccurrences(of: "##", with: "")
                result.append(attributed(of: string, with: UIFont.preferredFont(forTextStyle: .title2)))
            } else if line.hasPrefix("#") {
                let string = line.replacingOccurrences(of: "#", with: "")
                result.append(attributed(of: string, with: UIFont.preferredFont(forTextStyle: .largeTitle)))
            } else {
                result.append(attributed(of: String(line), with: UIFont.preferredFont(forTextStyle: .body)))
            }
        }
        return result
    }

    func attributed(of line: String, with font: UIFont) -> NSAttributedString {
        let foregroundColor: UIColor = ColorProvider.TextNorm
        return .init(string: line + "\n",
                     attributes: [.font: font, .foregroundColor: foregroundColor])
    }
}

final class PMAcknowledgementsViewController: UIViewController {
    var viewModel: PMAcknowledgementsViewModel
    lazy var textView = UITextView()

    // swiftlint:disable identifier_name
    init(vm: PMAcknowledgementsViewModel) {
        self.viewModel = vm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = .back(on: self, action: #selector(backButtonTapped))
        view.addSubview(textView)
        textView.adjustsFontForContentSizeCategory = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        textView.textContainerInset.left = 16
        textView.textContainerInset.right = 16
        textView.isEditable = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = viewModel.title
        textView.attributedText = viewModel.load()
        textView.contentOffset = .zero
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}
