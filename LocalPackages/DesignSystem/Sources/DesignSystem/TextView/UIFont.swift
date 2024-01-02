import SwiftUI

// swiftlint:disable force_unwrapping
public extension UIFont {
    static let caption2: UIFont = .preferredFont(forTextStyle: .caption2)
    static let caption: UIFont = .preferredFont(forTextStyle: .caption1)
    static let footnote: UIFont = .preferredFont(forTextStyle: .footnote)
    static let callout: UIFont = .preferredFont(forTextStyle: .callout)
    static let body: UIFont = .preferredFont(forTextStyle: .body)
    static let subheadline: UIFont = .preferredFont(forTextStyle: .subheadline)
    static let headline: UIFont = .preferredFont(forTextStyle: .headline)
    static let title3: UIFont = .preferredFont(forTextStyle: .title3)
    static let title2: UIFont = .preferredFont(forTextStyle: .title2)
    static let title: UIFont = .preferredFont(forTextStyle: .title1)
    static let largeTitle: UIFont = .preferredFont(forTextStyle: .largeTitle)
}

public extension UIFont {
    enum Leading {
        case loose
        case tight
    }

    private func addingAttributes(_ attributes: [UIFontDescriptor.AttributeName: Any]) -> UIFont {
        UIFont(descriptor: fontDescriptor.addingAttributes(attributes), size: pointSize)
    }

    static func system(size: CGFloat,
                       weight: UIFont.Weight,
                       design: UIFontDescriptor.SystemDesign = .default) -> UIFont {
        let descriptor = UIFont.systemFont(ofSize: size).fontDescriptor
            .addingAttributes([
                UIFontDescriptor.AttributeName.traits: [
                    UIFontDescriptor.TraitKey.weight: weight.rawValue
                ]
            ]).withDesign(design)!
        return UIFont(descriptor: descriptor, size: size)
    }

    static func system(_ style: UIFont.TextStyle, design: UIFontDescriptor.SystemDesign = .default) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style).withDesign(design)!
        return UIFont(descriptor: descriptor, size: 0)
    }

    func weight(_ weight: UIFont.Weight) -> UIFont {
        addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: weight.rawValue
            ]
        ])
    }

    func italic() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitItalic)!
        return UIFont(descriptor: descriptor, size: 0)
    }

    func bold() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitBold)!
        return UIFont(descriptor: descriptor, size: 0)
    }

    func leading(_ leading: Leading) -> UIFont {
        let descriptor = fontDescriptor
            .withSymbolicTraits(leading == .loose ? .traitLooseLeading : .traitTightLeading)!
        return UIFont(descriptor: descriptor, size: 0)
    }

    func smallCaps() -> UIFont {
        addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kLowerCaseType,
                    UIFontDescriptor.FeatureKey.selector: kLowerCaseSmallCapsSelector
                ],
                [
                    UIFontDescriptor.FeatureKey.type: kUpperCaseType,
                    UIFontDescriptor.FeatureKey.selector: kUpperCaseSmallCapsSelector
                ]
            ]
        ])
    }

    func lowercaseSmallCaps() -> UIFont {
        addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kLowerCaseType,
                    UIFontDescriptor.FeatureKey.selector: kLowerCaseSmallCapsSelector
                ]
            ]
        ])
    }

    func uppercaseSmallCaps() -> UIFont {
        addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kUpperCaseType,
                    UIFontDescriptor.FeatureKey.selector: kUpperCaseSmallCapsSelector
                ]
            ]
        ])
    }

    func monospacedDigit() -> UIFont {
        addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector
                ]
            ]
        ])
    }
}

// swiftlint:enable force_unwrapping
