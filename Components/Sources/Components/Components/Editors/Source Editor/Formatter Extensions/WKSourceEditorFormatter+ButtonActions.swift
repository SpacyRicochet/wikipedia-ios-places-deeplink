import Foundation
import ComponentsObjC

enum WKSourceEditorFormatterButtonAction {
    case add
    case remove
}

extension WKSourceEditorFormatter {
    
    // MARK: - Entry points to adding/removing formatting strings
    
    func toggleFormatting(formattingString: String, action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        toggleFormatting(startingFormattingString: formattingString, endingFormattingString: formattingString, action: action, in: textView)
    }
    
    func toggleFormatting(startingFormattingString: String, endingFormattingString: String, action: WKSourceEditorFormatterButtonAction, in textView: UITextView) {
        if case .remove = action {
            expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString, in: textView)
            if selectedRangeIsSurroundedByFormattingStrings(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString, in: textView) {
                removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString, in: textView)
            }
        } else {
            addStringFormattingCharacters(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString, in: textView)
        }
    }
    
    // MARK: - Expanding selected range methods
    
    private func expandSelectedRangeUpToNearestFormattingStrings(startingFormattingString: String, endingFormattingString: String, in textView: UITextView) {
        if let textPositions = textPositionsCloserToNearestFormattingStrings(startingFormattingString: startingFormattingString, endingFormattingString: endingFormattingString, in: textView) {
            textView.selectedTextRange = textView.textRange(from: textPositions.startPosition, to: textPositions.endPosition)
        }
    }
    
    private func textPositionsCloserToNearestFormattingStrings(startingFormattingString: String, endingFormattingString: String, in textView: UITextView) -> (startPosition: UITextPosition, endPosition: UITextPosition)? {
        
        guard let originalSelectedRange = textView.selectedTextRange else {
            return nil
        }
        
        let breakOnOppositeTag = startingFormattingString != endingFormattingString
        
        // loop backwards to find start
        var i = 0
        var finalStart: UITextPosition?
        while let newStart = textView.position(from: originalSelectedRange.start, offset: i) {
            let newRange = textView.textRange(from: newStart, to: originalSelectedRange.end)

            if rangeIsPrecededByFormattingString(range: newRange, formattingString: startingFormattingString, in: textView) {

                finalStart = newStart
                break
            }
            
            // Stop searching if you encounter a line break or another closing formatting string
            if rangeIsPrecededByFormattingString(range: newRange, formattingString: "\n", in: textView) {
                break
            }
            
            if breakOnOppositeTag && rangeIsPrecededByFormattingString(range: newRange, formattingString: endingFormattingString, in: textView) {
                break
            }
            
            i = i - 1
        }
        
        // loop forwards to find end
        i = 0
        var finalEnd: UITextPosition?
        while let newEnd = textView.position(from: originalSelectedRange.end, offset: i) {
            let newRange = textView.textRange(from: originalSelectedRange.start, to: newEnd)
            
            if rangeIsFollowedByFormattingString(range: newRange, formattingString: endingFormattingString, in: textView) {

                finalEnd = newEnd
                break
            }
            
            
            // Stop searching if you encounter a line break or another opening formatting string
            if rangeIsFollowedByFormattingString(range: newRange, formattingString: "\n", in: textView) {
                break
            }
            
            if breakOnOppositeTag && rangeIsFollowedByFormattingString(range: newRange, formattingString: startingFormattingString, in: textView) {
                break
            }
            
            i = i + 1
        }
        
        // Select new range
        guard let finalStart = finalStart,
                  let finalEnd = finalEnd else {
                      return nil
                  }
        
        return (finalStart, finalEnd)
    }
    
    // MARK: - Nearby formatting string determination
    
    private func selectedRangeIsSurroundedByFormattingString(formattingString: String, in textView: UITextView) -> Bool {
        selectedRangeIsSurroundedByFormattingStrings(startingFormattingString: formattingString, endingFormattingString: formattingString, in: textView)
    }
    
    private func selectedRangeIsSurroundedByFormattingStrings(startingFormattingString: String, endingFormattingString: String, in textView: UITextView) -> Bool {
        return rangeIsPrecededByFormattingString(range: textView.selectedTextRange, formattingString: startingFormattingString, in: textView) && rangeIsFollowedByFormattingString(range: textView.selectedTextRange, formattingString: endingFormattingString, in: textView)
    }
    
    private func rangeIsPrecededByFormattingString(range: UITextRange?, formattingString: String, in textView: UITextView) -> Bool {
        guard let range = range,
              let newStart = textView.position(from: range.start, offset: -formattingString.count) else {
            return false
        }
        
        guard let startingRange = textView.textRange(from: newStart, to: range.start),
              let startingString = textView.text(in: startingRange) else {
            return false
        }
        
        return startingString == formattingString
    }
    
    private func rangeIsFollowedByFormattingString(range: UITextRange?, formattingString: String, in textView: UITextView) -> Bool {
        guard let range = range,
              let newEnd = textView.position(from: range.end, offset: formattingString.count) else {
            return false
        }
        
        guard let endingRange = textView.textRange(from: range.end, to: newEnd),
              let endingString = textView.text(in: endingRange) else {
            return false
        }
        
        return endingString == formattingString
    }
    
    // MARK: Adding and removing text
    
    private func addStringFormattingCharacters(startingFormattingString: String, endingFormattingString: String, in textView: UITextView) {
        
        let startingCursorOffset = startingFormattingString.count
        let endingCursorOffset = endingFormattingString.count
        if let selectedRange = textView.selectedTextRange {
            let cursorPosition = textView.offset(from: textView.endOfDocument, to: selectedRange.end)
            if selectedRange.isEmpty {
                textView.replace(textView.selectedTextRange ?? UITextRange(), withText: startingFormattingString + endingFormattingString)

                let newPosition = textView.position(from: textView.endOfDocument, offset: cursorPosition - endingCursorOffset)
                textView.selectedTextRange = textView.textRange(from: newPosition ?? textView.endOfDocument, to: newPosition ?? textView.endOfDocument)
            } else {
                if let selectedSubstring = textView.text(in: selectedRange) {
                    textView.replace(textView.selectedTextRange ?? UITextRange(), withText: startingFormattingString + selectedSubstring + endingFormattingString)

                    let delta = endingFormattingString.count - startingFormattingString.count
                    let newStartPosition = textView.position(from: selectedRange.start, offset: startingCursorOffset)
                    let newEndPosition = textView.position(from: selectedRange.end, offset: endingCursorOffset - delta)
                    textView.selectedTextRange = textView.textRange(from: newStartPosition ?? textView.endOfDocument, to: newEndPosition ?? textView.endOfDocument)
                } else {
                    textView.replace(textView.selectedTextRange ?? UITextRange(), withText: startingFormattingString + endingFormattingString)
                }
            }
        }
    }
    
    private func removeSurroundingFormattingStringsFromSelectedRange(startingFormattingString: String, endingFormattingString: String, in textView: UITextView) {

        guard let originalSelectedTextRange = textView.selectedTextRange,
              let formattingTextStart = textView.position(from: originalSelectedTextRange.start, offset: -startingFormattingString.count),
              let formattingTextEnd = textView.position(from: originalSelectedTextRange.end, offset: endingFormattingString.count) else {
            return
        }
        
        guard let formattingTextStartRange = textView.textRange(from: formattingTextStart, to: originalSelectedTextRange.start),
              let formattingTextEndRange = textView.textRange(from: originalSelectedTextRange.end, to: formattingTextEnd) else {
            return
        }
        
        // Note: replacing end first ordering is important here, otherwise range gets thrown off if you begin with start.
        textView.replace(formattingTextEndRange, withText: "")
        textView.replace(formattingTextStartRange, withText: "")

        // Reset selection
        let delta = endingFormattingString.count - startingFormattingString.count
        guard
            let newSelectionStartPosition = textView.position(from: originalSelectedTextRange.start, offset: -startingFormattingString.count),
            let newSelectionEndPosition = textView.position(from: originalSelectedTextRange.end, offset: -endingFormattingString.count + delta) else {
            return
        }

        textView.selectedTextRange = textView.textRange(from: newSelectionStartPosition, to: newSelectionEndPosition)
    }
}
