import Foundation
import UIKit
import ComponentsObjC

/// This class facilitates communication between WKSourceEditorView and the underlying TextKit (1 and 2) frameworks, so that WKSourceEditorView is unaware of which framework is used.
/// When we need to drop TextKit 1, the goal is for all the adjustments to be in this one class

fileprivate var needsTextKit2: Bool {
    if #available(iOS 17, *) {
        return true
    } else {
        return false
    }
}

@objc final class WKSourceEditorSelectionState: NSObject {
    let isBold: Bool
    let isItalics: Bool
    
    init(isBold: Bool, isItalics: Bool) {
        self.isBold = isBold
        self.isItalics = isItalics
    }
}

final class WKSourceEditorTextFrameworkMediator: NSObject {
    
    let textView: UITextView
    let textKit1Storage: WKSourceEditorTextStorage?
    let textKit2Storage: NSTextContentStorage?
    
    private(set) var formatters: [WKSourceEditorFormatter] = []
    private(set) var boldItalicsFormatter: WKSourceEditorFormatterBoldItalics?
    
    var isSyntaxHighlightingEnabled: Bool = true {
        didSet {
            updateColorsAndFonts()
        }
    }
    
    override init() {

        let textView: UITextView
        if needsTextKit2 {
            if #available(iOS 16, *) {
                textView = UITextView(usingTextLayoutManager: true)
                textKit2Storage = textView.textLayoutManager?.textContentManager as? NSTextContentStorage
            } else {
                fatalError("iOS 15 cannot handle TextKit2")
            }
            textKit1Storage = nil
        } else {
            textKit1Storage = WKSourceEditorTextStorage()
            
            let layoutManager = NSLayoutManager()
            let container = NSTextContainer()

            container.widthTracksTextView = true

            layoutManager.addTextContainer(container)
            textKit1Storage?.addLayoutManager(layoutManager)

            textView = UITextView(frame: .zero, textContainer: container)
            textKit2Storage = nil
        }
        
        self.textView = textView
        
        textView.textContainerInset = .init(top: 16, left: 8, bottom: 16, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.keyboardDismissMode = .interactive
        
        // Note: There is improved selection performance / fixed console constraint errors with these next two lines. Leaving them commented out for now.
        
        // textView.autocorrectionType = .no
        // textView.spellCheckingType = .no
        
        super.init()
        
        if needsTextKit2 {
            textKit2Storage?.delegate = self
        } else {
            textKit1Storage?.storageDelegate = self
        }
    }
    
    // MARK: Internal
    
    func updateColorsAndFonts() {
        
        let colors = self.colors
        let fonts = self.fonts
        
        let boldItalicsFormatter = WKSourceEditorFormatterBoldItalics(colors: colors, fonts: fonts)
        self.formatters = [WKSourceEditorFormatterBase(colors: colors, fonts: fonts),
                boldItalicsFormatter]
        self.boldItalicsFormatter = boldItalicsFormatter
        
        if needsTextKit2 {
            if #available(iOS 16.0, *) {
                let textContentManager = textView.textLayoutManager?.textContentManager
                textContentManager?.performEditingTransaction({
                    
                    guard let attributedString = (textContentManager as? NSTextContentStorage)?.textStorage else {
                        return
                    }
                    
                    let colors = self.colors
                    let fonts = self.fonts
                    let range = NSRange(location: 0, length: attributedString.length)
                    for formatter in formatters {
                        formatter.update(colors, in: attributedString, in: range)
                        formatter.update(fonts, in: attributedString, in: range)
                    }
                })
            }
        } else {
            textKit1Storage?.updateColorsAndFonts()
        }
    }
    
    func selectionState(selectedDocumentRange: NSRange) -> WKSourceEditorSelectionState {
        
        if needsTextKit2 {
            guard let textKit2Data = textkit2SelectionData(selectedDocumentRange: selectedDocumentRange) else {
                return WKSourceEditorSelectionState(isBold: false, isItalics: false)
            }
            
            let isBold = boldItalicsFormatter?.attributedString(textKit2Data.paragraphAttributedString, isBoldIn: textKit2Data.paragraphSelectedRange) ?? false
            let isItalics = boldItalicsFormatter?.attributedString(textKit2Data.paragraphAttributedString, isItalicsIn: textKit2Data.paragraphSelectedRange) ?? false
            
            return WKSourceEditorSelectionState(isBold: isBold, isItalics: isItalics)
        } else {
            guard let textKit1Storage else {
                return WKSourceEditorSelectionState(isBold: false, isItalics: false)
            }
                        
            let isBold = boldItalicsFormatter?.attributedString(textKit1Storage, isBoldIn: selectedDocumentRange) ?? false
            let isItalics = boldItalicsFormatter?.attributedString(textKit1Storage, isItalicsIn: selectedDocumentRange) ?? false
            
            return WKSourceEditorSelectionState(isBold: isBold, isItalics: isItalics)
        }
    }
    
    func textkit2SelectionData(selectedDocumentRange: NSRange) -> (paragraphAttributedString: NSMutableAttributedString, paragraphSelectedRange: NSRange)? {
        guard needsTextKit2 else {
            return nil
        }
        
        // Pulling the paragraph element that contains the selection will have an attributed string with the populated attributes
        if #available(iOS 16.0, *) {
            guard let textKit2Storage,
                  let layoutManager = textView.textLayoutManager,
                  let selectedDocumentTextRange = textKit2Storage.textRangeForDocumentNSRange(selectedDocumentRange),
                  let paragraphElement = layoutManager.textLayoutFragment(for: selectedDocumentTextRange.location)?.textElement as? NSTextParagraph,
                  let paragraphRange = paragraphElement.elementRange else {
                return nil
            }
            
            guard let selectedParagraphRange = textKit2Storage.offsetDocumentNSRangeWithParagraphRange(documentNSRange: selectedDocumentRange, paragraphRange: paragraphRange) else {
                return nil
            }
            
            return (NSMutableAttributedString(attributedString: paragraphElement.attributedString), selectedParagraphRange)
        }
        
        return nil
    }
}

extension WKSourceEditorTextFrameworkMediator: WKSourceEditorStorageDelegate {
    
    var colors: WKSourceEditorColors {
        let colors = WKSourceEditorColors()
        colors.baseForegroundColor = WKAppEnvironment.current.theme.text
        colors.orangeForegroundColor = isSyntaxHighlightingEnabled ? WKAppEnvironment.current.theme.editorOrange : WKAppEnvironment.current.theme.text
        return colors
    }
    
    var fonts: WKSourceEditorFonts {
        let fonts = WKSourceEditorFonts()
        let traitCollection = UITraitCollection(preferredContentSizeCategory: WKAppEnvironment.current.articleAndEditorTextSize)
        let baseFont = WKFont.for(.body, compatibleWith: traitCollection)
        fonts.baseFont = baseFont
        
        fonts.boldFont = isSyntaxHighlightingEnabled ? WKFont.for(.boldBody, compatibleWith: traitCollection) : baseFont
        fonts.italicsFont = isSyntaxHighlightingEnabled ? WKFont.for(.italicsBody, compatibleWith: traitCollection) : baseFont
        fonts.boldItalicsFont = isSyntaxHighlightingEnabled ? WKFont.for(.boldItalicsBody, compatibleWith: traitCollection) : baseFont
        return fonts
    }
}

 extension WKSourceEditorTextFrameworkMediator: NSTextContentStorageDelegate {

    func textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
        
        guard needsTextKit2 else {
            return nil
        }
        
        guard let originalText = textContentStorage.textStorage?.attributedSubstring(from: range),
              originalText.length > 0 else {
            return nil
        }
        let attributedString = NSMutableAttributedString(attributedString: originalText)
        let paragraphRange = NSRange(location: 0, length: originalText.length)
        
        for formatter in formatters {
            formatter.addSyntaxHighlighting(to: attributedString, in: paragraphRange)
        }
        
        return NSTextParagraph(attributedString: attributedString)
    }
}

fileprivate extension NSTextContentStorage {
    func textRangeForDocumentNSRange(_ documentNSRange: NSRange) -> NSTextRange? {
        guard let start = location(documentRange.location, offsetBy: documentNSRange.location),
                let end = location(start, offsetBy: documentNSRange.length) else {
            return nil
        }
        
        return NSTextRange(location: start, end: end)
    }
    
    func offsetDocumentNSRangeWithParagraphRange(documentNSRange: NSRange, paragraphRange: NSTextRange) -> NSRange? {
        let startOffset = offset(from: documentRange.location, to: paragraphRange.location)
        let newNSRange = NSRange(location: documentNSRange.location - startOffset, length: documentNSRange.length)
        
        guard newNSRange.location >= 0 else {
            return nil
        }
        
        return newNSRange
    }
}
