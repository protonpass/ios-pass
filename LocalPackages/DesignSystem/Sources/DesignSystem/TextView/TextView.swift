import SwiftUI

// swiftlint:disable discouraged_optional_boolean
/// A SwiftUI TextView implementation that supports both scrolling and auto-sizing layouts
public struct TextView: View {
    @Environment(\.layoutDirection) private var layoutDirection

    @Binding private var text: NSAttributedString
    @Binding private var isEmpty: Bool

    @State private var calculatedHeight: CGFloat = 44

    private var onEditingChanged: (() -> Void)?
    private var shouldEditInRange: ((Range<String.Index>, String) -> Bool)?
    private var onCommit: (() -> Void)?

    // swiftlint:disable:next discouraged_anyview
    var placeholderView: AnyView?
    var foregroundColor: UIColor = .label
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var multilineTextAlignment: TextAlignment = .leading
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var returnKeyType: UIReturnKeyType?
    var clearsOnInsertion = false
    var autocorrection: UITextAutocorrectionType = .default
    var truncationMode: NSLineBreakMode = .byTruncatingTail
    var isEditable = true
    var isSelectable = true
    var isScrollingEnabled = false
    var enablesReturnKeyAutomatically: Bool?
    var autoDetectionTypes: UIDataDetectorTypes = []
    var allowRichText: Bool

    /// Makes a new TextView with the specified configuration
    /// - Parameters:
    ///   - text: A binding to the text
    ///   - shouldEditInRange: A closure that's called before an edit it applied, allowing the consumer to prevent
    /// the change
    ///   - onEditingChanged: A closure that's called after an edit has been applied
    ///   - onCommit: If this is provided, the field will automatically lose focus when the return key is pressed
    public init(_ text: Binding<String>,
                shouldEditInRange: ((Range<String.Index>, String) -> Bool)? = nil,
                onEditingChanged: (() -> Void)? = nil,
                onCommit: (() -> Void)? = nil) {
        _text = Binding(get: { NSAttributedString(string: text.wrappedValue) },
                        set: { text.wrappedValue = $0.string })

        _isEmpty = Binding(get: { text.wrappedValue.isEmpty },
                           set: { _ in })

        self.onCommit = onCommit
        self.shouldEditInRange = shouldEditInRange
        self.onEditingChanged = onEditingChanged

        allowRichText = false
    }

    /// Makes a new TextView that supports `NSAttributedString`
    /// - Parameters:
    ///   - text: A binding to the attributed text
    ///   - onEditingChanged: A closure that's called after an edit has been applied
    ///   - onCommit: If this is provided, the field will automatically lose focus when the return key is pressed
    public init(_ text: Binding<NSAttributedString>,
                onEditingChanged: (() -> Void)? = nil,
                onCommit: (() -> Void)? = nil) {
        _text = text
        _isEmpty = Binding(get: { text.wrappedValue.string.isEmpty },
                           set: { _ in })

        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged

        allowRichText = true
    }

    public var body: some View {
        Representable(text: $text,
                      calculatedHeight: $calculatedHeight,
                      foregroundColor: foregroundColor,
                      autocapitalization: autocapitalization,
                      multilineTextAlignment: multilineTextAlignment,
                      font: font,
                      returnKeyType: returnKeyType,
                      clearsOnInsertion: clearsOnInsertion,
                      autocorrection: autocorrection,
                      truncationMode: truncationMode,
                      isEditable: isEditable,
                      isSelectable: isSelectable,
                      isScrollingEnabled: isScrollingEnabled,
                      enablesReturnKeyAutomatically: enablesReturnKeyAutomatically,
                      autoDetectionTypes: autoDetectionTypes,
                      allowsRichText: allowRichText,
                      onEditingChanged: onEditingChanged,
                      shouldEditInRange: shouldEditInRange,
                      onCommit: onCommit)
            .frame(minHeight: isScrollingEnabled ? 0 : calculatedHeight,
                   maxHeight: isScrollingEnabled ? .infinity : calculatedHeight)
            .background(placeholderView?
                .foregroundColor(Color(.placeholderText))
                .multilineTextAlignment(multilineTextAlignment)
                .font(Font(font))
                .padding(.horizontal, isScrollingEnabled ? 5 : 0)
                .padding(.vertical, isScrollingEnabled ? 8 : 0)
                .opacity(isEmpty ? 1 : 0),
                alignment: .topLeading)
    }
}

final class UIKitTextView: UITextView {
    override var keyCommands: [UIKeyCommand]? {
        (super.keyCommands ?? []) + [
            UIKeyCommand(input: UIKeyCommand.inputEscape,
                         modifierFlags: [],
                         action: #selector(escape))
        ]
    }

    @objc
    private func escape(_ sender: Any) {
        resignFirstResponder()
    }
}

// swiftlint:enable discouraged_optional_boolean
