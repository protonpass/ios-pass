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

@preconcurrency import Combine
import DesignSystem
import DocScanner
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import Screens
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
                                      files: viewModel.fileUiModels,
                                      isUploadingFile: viewModel.isUploadingFile,
                                      handler: viewModel,
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
    let files: [FileAttachmentUiModel]
    let isUploadingFile: Bool
    let handler: any FileAttachmentsEditHandler
    weak var scanResponsePublisher: ScanResponsePublisher?

    func makeUIView(context: Context) -> CreateEditNoteContentUIView {
        let view = CreateEditNoteContentUIView()
        view.delegate = context.coordinator
        view.bind(title: title, content: content)
        view.scanResponsePublisher = scanResponsePublisher
        view.handler = handler
        return view
    }

    func updateUIView(_ view: CreateEditNoteContentUIView, context: Context) {
        view.update(files: files, isUploadingFile: isUploadingFile)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    final class Coordinator: CreateEditNoteContentUIViewDelegate {
        let parent: CreateEditNoteContentView

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

private protocol CreateEditNoteContentUIViewDelegate: AnyObject, Sendable {
    @MainActor func titleUpdated(_ text: String)
    @MainActor func contentUpdated(_ text: String)
}

@MainActor
private final class CreateEditNoteContentUIView: UIView {
    private var lastFileCount: Int?
    private let padding: CGFloat = 16

    /// `UITextView` has its own offset that we need to take into account to properly align with title and the
    /// custom placeholder
    private let textViewOffset: CGFloat = 4

    private let scrollView = UIScrollView()

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

    private var contentTextViewHeight: NSLayoutConstraint?
    private lazy var contentTextView: UITextView = {
        let tv = UITextView()
        tv.font = .body
        tv.textColor = PassColor.textNorm
        tv.backgroundColor = .clear
        tv.delegate = self
        tv.isScrollEnabled = false
        return tv
    }()

    private lazy var filesStackView: UIStackView = {
        let sv = UIStackView()
        sv.backgroundColor = .clear
        sv.spacing = DesignConstant.sectionPadding
        sv.axis = .vertical
        return sv
    }()

    weak var delegate: (any CreateEditNoteContentUIViewDelegate)?
    weak var handler: (any FileAttachmentsEditHandler)?

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

    deinit {
        cancellables.removeAll()
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
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
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
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
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
                                                             constant: padding),
            contentPlaceholderLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                              constant: -padding)
        ])

        // Content text view
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentTextView)
        // Set a big enough height by default and update this constraint as text changes
        contentTextViewHeight = contentTextView.heightAnchor.constraint(equalToConstant: 500)
        contentTextViewHeight?.isActive = true
        NSLayoutConstraint.activate([
            contentTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor),
            contentTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                     constant: padding - 5),
            contentTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                      constant: -padding)
        ])

        // Files stack view
        filesStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(filesStackView)
        NSLayoutConstraint.activate([
            filesStackView.topAnchor.constraint(equalTo: contentTextView.bottomAnchor,
                                                constant: padding),
            filesStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                    constant: padding - 5),
            filesStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                     constant: -padding),
            filesStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                                   constant: -padding)
        ])

        titleTextField.setOnTextChangeListener { [weak self] in
            guard let self else { return }
            if let text = titleTextField.text {
                delegate?.titleUpdated(text)
            }
        }
    }

    func updatePlaceholderVisibility() {
        contentPlaceholderLabel.alpha = contentTextView.text.isEmpty ? 1 : 0
    }

    func update(files: [FileAttachmentUiModel], isUploadingFile: Bool) {
        titleTextField.isUserInteractionEnabled = !isUploadingFile
        contentTextView.isUserInteractionEnabled = !isUploadingFile

        for view in filesStackView.arrangedSubviews {
            filesStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for file in files {
            if let handler {
                let row =
                    FileAttachmentRow(mode: .edit(onRename: { handler.showRenameAlert(attachment: file) },
                                                  onDelete: { handler.showDeleteAlert(attachment: file) },
                                                  onRetryUpload: { handler.retryUpload(attachment: file) }),
                                      itemContentType: handler.itemContentType,
                                      uiModel: file,
                                      primaryTintColor: handler.fileAttachmentsSectionPrimaryColor,
                                      secondaryTintColor: handler.fileAttachmentsSectionSecondaryColor)
                    .disabled(isUploadingFile)
                let viewController = UIHostingController(rootView: row)
                viewController.view.backgroundColor = .clear
                viewController.view.translatesAutoresizingMaskIntoConstraints = false
                filesStackView.addArrangedSubview(viewController.view)
            }
        }

        filesStackView.layoutIfNeeded()
        if let lastFileCount, files.count > lastFileCount {
            // New file added => scroll to the bottom
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self else { return }
                // Wait for attachment sheet is fully dismissed before scrolling to the bottom
                scrollView.scrollToBottom()
            }
        }
        lastFileCount = files.count
    }

    func transformIntoNote(document: ScannedDocument) {
        var note = contentTextView.text ?? ""
        defer {
            contentTextView.text = note
            delegate?.contentUpdated(note)
        }
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

    func updateContentTextViewHeight() {
        let size = contentTextView.sizeThatFits(CGSize(width: contentTextView.frame.width,
                                                       height: CGFloat.greatestFiniteMagnitude))
        contentTextViewHeight?.constant = size.height
        layoutIfNeeded()
    }
}

extension CreateEditNoteContentUIView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Note title is focused automatically by default
        // we update the height of contentTextView here because its height
        // is not known at the initialization of this page
        updateContentTextViewHeight()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension CreateEditNoteContentUIView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if let text = textView.text {
            delegate?.contentUpdated(text)
        }
        updatePlaceholderVisibility()
        updateContentTextViewHeight()
    }
}
