import Foundation

class WKEditorToolbarPlainView: WKEditorToolbarView {
    
    // MARK: Properties
    
    @IBOutlet private weak var boldButton: WKEditorToolbarButton!
    @IBOutlet private weak var italicsButton: WKEditorToolbarButton!
    @IBOutlet private weak var citationButton: WKEditorToolbarButton!
    @IBOutlet private weak var linkButton: WKEditorToolbarButton!
    @IBOutlet private weak var templateButton: WKEditorToolbarButton!
    @IBOutlet private weak var commentButton: WKEditorToolbarButton!
    
    weak var delegate: WKEditorInputViewDelegate?
    
    // MARK: Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
        boldButton.setImage(WKIcon.bold, for: .normal)
        boldButton.addTarget(self, action: #selector(tappedBold), for: .touchUpInside)
        
        italicsButton.setImage(WKIcon.italics, for: .normal)
        italicsButton.addTarget(self, action: #selector(tappedItalics), for: .touchUpInside)
        
        citationButton.setImage(WKIcon.citation, for: .normal)
        citationButton.addTarget(self, action: #selector(tappedCitation), for: .touchUpInside)
        
        linkButton.setImage(WKIcon.link, for: .normal)
        linkButton.addTarget(self, action: #selector(tappedLink), for: .touchUpInside)
        
        templateButton.setImage(WKIcon.template, for: .normal)
        templateButton.addTarget(self, action: #selector(tappedTemplate), for: .touchUpInside)
        
        commentButton.setImage(WKIcon.exclamationPointCircle, for: .normal)
        commentButton.addTarget(self, action: #selector(tappedComment), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonSelectionState(_:)), name: Notification.WKSourceEditorSelectionState, object: nil)
    }
    
    // MARK: - Notifications
    
    @objc private func updateButtonSelectionState(_ notification: NSNotification) {
        guard let selectionState = notification.userInfo?[Notification.WKSourceEditorSelectionStateKey] as? WKSourceEditorSelectionState else {
            return
        }
        
        boldButton.isSelected = selectionState.isBold
        italicsButton.isSelected = selectionState.isItalics
    }
    
    // MARK: Button Actions
    
    @objc private func tappedBold() {
        delegate?.didTapBold(isSelected: boldButton.isSelected)
    }

    @objc private func tappedItalics() {
        delegate?.didTapItalics(isSelected: italicsButton.isSelected)
    }

    @objc private func tappedCitation() {
    }

    @objc private func tappedTemplate() {
    }

    @objc private func tappedComment() {
    }

    @objc private func tappedLink() {
    }
}
