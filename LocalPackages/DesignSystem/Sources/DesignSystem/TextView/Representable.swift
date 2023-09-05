import SwiftUI

// swiftlint:disable discouraged_optional_boolean
extension TextView {
    struct Representable: UIViewRepresentable {
        @Binding var text: NSAttributedString
        @Binding var calculatedHeight: CGFloat

        let foregroundColor: UIColor
        let autocapitalization: UITextAutocapitalizationType
        var multilineTextAlignment: TextAlignment
        let font: UIFont
        let returnKeyType: UIReturnKeyType?
        let clearsOnInsertion: Bool
        let autocorrection: UITextAutocorrectionType
        let truncationMode: NSLineBreakMode
        let isEditable: Bool
        let isSelectable: Bool
        let isScrollingEnabled: Bool
        let enablesReturnKeyAutomatically: Bool?
        var autoDetectionTypes: UIDataDetectorTypes = []
        var allowsRichText: Bool

        var onEditingChanged: (() -> Void)?
        var shouldEditInRange: ((Range<String.Index>, String) -> Bool)?
        var onCommit: (() -> Void)?

        func makeUIView(context: Context) -> UIKitTextView {
            context.coordinator.textView.attributedText = text
            return context.coordinator.textView
        }

        func updateUIView(_ view: UIKitTextView, context: Context) {
            context.coordinator.update(representable: self)
        }

        @discardableResult
        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text,
                        calculatedHeight: $calculatedHeight,
                        shouldEditInRange: shouldEditInRange,
                        onEditingChanged: onEditingChanged,
                        onCommit: onCommit)
        }
    }
}

// swiftlint:enable discouraged_optional_boolean
