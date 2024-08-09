//
// CreateEditNoteView.swift
// Proton Pass - Created on 07/07/2022.
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

import Combine
import DesignSystem
import DocScanner
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct CreateEditNoteView: View {
    @StateObject private var viewModel: CreateEditNoteViewModel

    init(viewModel: CreateEditNoteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            CreateEditNoteContentView(title: $viewModel.title,
                                      content: $viewModel.note,
                                      scanResponsePublisher: viewModel.scanResponsePublisher)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .itemCreateEditSetUp(viewModel)
        }
        .scannerSheet(isPresented: $viewModel.isShowingScanner,
                      interpreter: viewModel.interpretor,
                      resultStream: viewModel.scanResponsePublisher)
    }
}

/// Fallback to `UIKit` because `SwiftUI` doesn't handle well 2 `TextField` in a `ScrollView`
/// (e.g enter new line sometimes not working, random cursor position when focusing on note's content)
private struct CreateEditNoteContentView: UIViewRepresentable {
    @Binding var title: String
    @Binding var content: String
    weak var scanResponsePublisher: ScanResponsePublisher?

    func makeUIView(context: Context) -> CreateEditNoteContentUIView {
        let view = CreateEditNoteContentUIView()
        view.delegate = context.coordinator
        view.bind(title: title, content: content)
        view.scanResponsePublisher = scanResponsePublisher
        return view
    }

    func updateUIView(_ view: CreateEditNoteContentUIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: CreateEditNoteContentUIViewDelegate {
        var parent: CreateEditNoteContentView

        init(_ parent: CreateEditNoteContentView) {
            self.parent = parent
        }

        func titleUpdated(_ text: String) {
            parent.title = text
        }

        func contentUpdated(_ text: String) {
            parent.content = text
        }
    }
}

private protocol CreateEditNoteContentUIViewDelegate: AnyObject {
    func titleUpdated(_ text: String)
    func contentUpdated(_ text: String)
}

private final class CreateEditNoteContentUIView: UIView {
    private let padding: CGFloat = 16

    /// `UITextView` has its own offset that we need to take into account to properly align with title and the
    /// custom placeholder
    private let textViewOffset: CGFloat = 4

    /// `UITextView` does not support placeholder out of the box so we have to manually add it
    private lazy var contentPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = #localized("Note")
        label.textColor = .placeholderText
        label.alpha = 0
        return label
    }()

    private lazy var titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = #localized("Untitled")
        tf.font = .title.bold()
        tf.textColor = PassColor.textNorm
        tf.delegate = self
        return tf
    }()

    private lazy var contentTextView: UITextView = {
        let tv = UITextView()
        tv.font = .body
        tv.textColor = PassColor.textNorm
        tv.backgroundColor = .clear
        tv.delegate = self
        tv.contentInset = .init(top: 0, left: padding, bottom: 0, right: padding)
        return tv
    }()

    weak var delegate: (any CreateEditNoteContentUIViewDelegate)?

    private var cancellables = Set<AnyCancellable>()
    weak var scanResponsePublisher: ScanResponsePublisher? {
        didSet {
            scanResponsePublisher?
                .receive(on: DispatchQueue.main)
                .sink { _ in } receiveValue: { [weak self] result in
                    guard let self, let result else { return }
                    if let document = result as? ScannedDocument {
                        transformIntoNote(document: document)
                    } else {
                        assertionFailure("Expecting ScannedDocument as result")
                    }
                }
                .store(in: &cancellables)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
        titleTextField.becomeFirstResponder()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String, content: String) {
        titleTextField.text = title
        contentTextView.text = content
        updatePlaceholderVisibility()
    }
}

private extension CreateEditNoteContentUIView {
    func setUpUI() {
        // Root scroll view
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.widthAnchor.constraint(equalTo: widthAnchor)
        ])

        // Root container view
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        // Title text field
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleTextField)
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                    constant: padding),
            titleTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                     constant: -padding)
        ])

        // Content placeholder label
        contentPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentPlaceholderLabel)
        NSLayoutConstraint.activate([
            contentPlaceholderLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor,
                                                         constant: 2 * textViewOffset),
            contentPlaceholderLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                             constant: padding + textViewOffset),
            contentPlaceholderLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                              constant: -padding)
        ])

        // Content text view
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentTextView)
        NSLayoutConstraint.activate([
            contentTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor),
            contentTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    func updatePlaceholderVisibility() {
        contentPlaceholderLabel.alpha = contentTextView.text.isEmpty ? 1 : 0
    }

    func transformIntoNote(document: ScannedDocument) {
        var note = contentTextView.text ?? ""
        defer { contentTextView.text = note }
        for (index, page) in document.scannedPages.enumerated() {
            note += page.text.reduce(into: "") { partialResult, next in
                partialResult = partialResult + "\n" + next
            }

            if index != document.scannedPages.count - 1 {
                // Add an empty line between pages
                note += "\n\n"
            }
        }
    }
}

extension CreateEditNoteContentUIView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            delegate?.titleUpdated(text)
        }
    }
}

extension CreateEditNoteContentUIView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if let text = textView.text {
            delegate?.contentUpdated(text)
        }
        updatePlaceholderVisibility()
    }
}
