import AppKit

protocol NotepadTextViewDelegate: AnyObject {
    func textViewDidChangeCursorPosition(line: Int, column: Int)
    func textViewDidChangeContent()
    func textViewDidRequestOpenURL(_ url: URL)
    func textViewDidChangeFormatting(bold: Bool, italic: Bool, strikethrough: Bool, underline: Bool)
}

class NotepadTextView: NSTextView {
    weak var notepadDelegate: NotepadTextViewDelegate?
    
    var baseFontSize: CGFloat = 14.0
    var zoomPercentage: Int = 100
    var isWordWrapEnabled: Bool = true
    
    convenience init(contentSize: NSSize) {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(containerSize: NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        
        self.init(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
    }

    convenience override init(frame frameRect: NSRect) {
        self.init(contentSize: frameRect.size)
    }

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        self.isEditable = true
        self.isSelectable = true
        self.allowsUndo = true
        self.isRichText = true
        self.usesFontPanel = true
        self.isAutomaticQuoteSubstitutionEnabled = false
        self.isAutomaticDashSubstitutionEnabled = false
        self.isAutomaticTextReplacementEnabled = false
        self.isContinuousSpellCheckingEnabled = false
        self.font = ThemeManager.shared.editorFont(size: baseFontSize)
        self.backgroundColor = ThemeManager.shared.editorBackgroundColor
        self.textColor = ThemeManager.shared.editorTextColor
        self.insertionPointColor = ThemeManager.shared.editorInsertionPointColor
        self.textContainerInset = NSSize(width: 4, height: 4)
        
        self.minSize = NSSize(width: 0, height: 0)
        self.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        self.isVerticallyResizable = true
        self.isHorizontallyResizable = false
        self.autoresizingMask = [.width]
        
        registerForDraggedTypes([.fileURL, .string])
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override var canBecomeKeyView: Bool {
        return true
    }
    
    func applyTheme() {
        self.backgroundColor = ThemeManager.shared.editorBackgroundColor
        self.textColor = ThemeManager.shared.editorTextColor
        self.insertionPointColor = ThemeManager.shared.editorInsertionPointColor
        updateFontZoom()
    }
    
    func updateFontZoom() {
        let actualSize = max(6.0, baseFontSize * CGFloat(zoomPercentage) / 100.0)
        let fontName = self.font?.fontName ?? "Consolas"
        if let newFont = NSFont(name: fontName, size: actualSize) {
            self.font = newFont
        } else {
            self.font = ThemeManager.shared.editorFont(size: actualSize)
        }
    }
    
    func setWordWrap(_ enabled: Bool) {
        isWordWrapEnabled = enabled
        guard let container = self.textContainer,
              let scrollView = self.enclosingScrollView else { return }
        
        if enabled {
            isHorizontallyResizable = false
            autoresizingMask = [.width]
            container.widthTracksTextView = true
            container.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            scrollView.hasHorizontalScroller = false
        } else {
            isHorizontallyResizable = true
            autoresizingMask = []
            container.widthTracksTextView = false
            container.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            scrollView.hasHorizontalScroller = true
            maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }
        needsDisplay = true
    }
    
    override func setSelectedRanges(_ ranges: [NSValue], affinity: NSSelectionAffinity, stillSelecting: Bool) {
        super.setSelectedRanges(ranges, affinity: affinity, stillSelecting: stillSelecting)
        updateCursorPosition()
        updateFormattingState()
    }
    
    override func didChangeText() {
        super.didChangeText()
        updateCursorPosition()
        updateFormattingState()
        notepadDelegate?.textViewDidChangeContent()
    }
    
    func updateCursorPosition() {
        let cursorIndex = selectedRange().location
        let fullText = (self.string as NSString)
        if cursorIndex > fullText.length { return }
        
        let textBefore = fullText.substring(to: cursorIndex)
        let lines = textBefore.components(separatedBy: "\n")
        let line = lines.count
        let col = (lines.last?.utf16.count ?? 0) + 1
        
        notepadDelegate?.textViewDidChangeCursorPosition(line: line, column: col)
    }
    
    func updateFormattingState() {
        let range = selectedRange()
        let attrs: [NSAttributedString.Key: Any]
        if range.length > 0, let textStorage = self.textStorage, range.location < textStorage.length {
            attrs = textStorage.attributes(at: range.location, effectiveRange: nil)
        } else {
            attrs = typingAttributes
        }
        
        let currentFont = (attrs[.font] as? NSFont) ?? self.font ?? ThemeManager.shared.editorFont(size: baseFontSize)
        let traits = NSFontManager.shared.traits(of: currentFont)
        var isBold = traits.contains(.boldFontMask)
        var isItalic = traits.contains(.italicFontMask)
        
        let strikeVal = (attrs[.strikethroughStyle] as? Int) ?? 0
        var isStrike = strikeVal != 0
        
        let underVal = (attrs[.underlineStyle] as? Int) ?? 0
        var isUnder = underVal != 0
        
        if range.length > 0 {
            let fullText = (self.string as NSString)
            if range.location + range.length <= fullText.length {
                let selectedText = fullText.substring(with: range)
                if selectedText.hasPrefix("**") && selectedText.hasSuffix("**") && selectedText.count >= 4 {
                    isBold = true
                }
                if selectedText.hasPrefix("*") && selectedText.hasSuffix("*") && selectedText.count >= 2 {
                    isItalic = true
                }
                if selectedText.hasPrefix("~~") && selectedText.hasSuffix("~~") && selectedText.count >= 4 {
                    isStrike = true
                }
                if selectedText.hasPrefix("<u>") && selectedText.hasSuffix("</u>") && selectedText.count >= 7 {
                    isUnder = true
                }
            }
        }
        
        notepadDelegate?.textViewDidChangeFormatting(bold: isBold, italic: isItalic, strikethrough: isStrike, underline: isUnder)
    }
    
    // Windows F5 feature: Time and Date insertion
    func insertTimeDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd/MM/yyyy"
        let timestamp = formatter.string(from: Date())
        insertText(timestamp, replacementRange: selectedRange())
    }
    
    override func keyDown(with event: NSEvent) {
        // F5 shortcut for Date/Time
        if event.keyCode == 96 { // F5 keycode
            insertTimeDate()
            return
        }
        super.keyDown(with: event)
    }
    
    // Drag & Drop
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pboard = sender.draggingPasteboard
        if pboard.types?.contains(.fileURL) == true {
            return .copy
        }
        return super.draggingEntered(sender)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        if let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let firstURL = urls.first {
            notepadDelegate?.textViewDidRequestOpenURL(firstURL)
            return true
        }
        return super.performDragOperation(sender)
    }
    
    // MARK: - Text Formatting & Markdown
    
    func toggleBold(markdownMode: Bool) {
        if markdownMode {
            wrapSelectionWith(prefix: "**", suffix: "**")
            return
        }
        let range = selectedRange()
        guard let textStorage = self.textStorage else { return }
        if range.length == 0 {
            var attrs = typingAttributes
            let currentFont = (attrs[.font] as? NSFont) ?? self.font ?? ThemeManager.shared.editorFont(size: baseFontSize)
            let isBold = NSFontManager.shared.traits(of: currentFont).contains(.boldFontMask)
            let newFont = isBold ? NSFontManager.shared.convert(currentFont, toNotHaveTrait: .boldFontMask) : NSFontManager.shared.convert(currentFont, toHaveTrait: .boldFontMask)
            attrs[.font] = newFont
            typingAttributes = attrs
            return
        }
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            let currentFont = (value as? NSFont) ?? self.font ?? ThemeManager.shared.editorFont(size: self.baseFontSize)
            let isBold = NSFontManager.shared.traits(of: currentFont).contains(.boldFontMask)
            let newFont = isBold ? NSFontManager.shared.convert(currentFont, toNotHaveTrait: .boldFontMask) : NSFontManager.shared.convert(currentFont, toHaveTrait: .boldFontMask)
            textStorage.addAttribute(.font, value: newFont, range: subrange)
        }
        textStorage.endEditing()
        didChangeText()
    }
    
    func toggleItalic(markdownMode: Bool) {
        if markdownMode {
            wrapSelectionWith(prefix: "*", suffix: "*")
            return
        }
        let range = selectedRange()
        guard let textStorage = self.textStorage else { return }
        if range.length == 0 {
            var attrs = typingAttributes
            let currentFont = (attrs[.font] as? NSFont) ?? self.font ?? ThemeManager.shared.editorFont(size: baseFontSize)
            let isItalic = NSFontManager.shared.traits(of: currentFont).contains(.italicFontMask)
            let newFont = isItalic ? NSFontManager.shared.convert(currentFont, toNotHaveTrait: .italicFontMask) : NSFontManager.shared.convert(currentFont, toHaveTrait: .italicFontMask)
            attrs[.font] = newFont
            typingAttributes = attrs
            return
        }
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            let currentFont = (value as? NSFont) ?? self.font ?? ThemeManager.shared.editorFont(size: self.baseFontSize)
            let isItalic = NSFontManager.shared.traits(of: currentFont).contains(.italicFontMask)
            let newFont = isItalic ? NSFontManager.shared.convert(currentFont, toNotHaveTrait: .italicFontMask) : NSFontManager.shared.convert(currentFont, toHaveTrait: .italicFontMask)
            textStorage.addAttribute(.font, value: newFont, range: subrange)
        }
        textStorage.endEditing()
        didChangeText()
    }
    
    func toggleStrikethrough(markdownMode: Bool) {
        if markdownMode {
            wrapSelectionWith(prefix: "~~", suffix: "~~")
            return
        }
        let range = selectedRange()
        guard let textStorage = self.textStorage else { return }
        if range.length == 0 {
            var attrs = typingAttributes
            let cur = (attrs[.strikethroughStyle] as? Int) ?? 0
            attrs[.strikethroughStyle] = cur == 0 ? NSUnderlineStyle.single.rawValue : 0
            typingAttributes = attrs
            return
        }
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.strikethroughStyle, in: range, options: []) { value, subrange, _ in
            let cur = (value as? Int) ?? 0
            let newStyle = cur == 0 ? NSUnderlineStyle.single.rawValue : 0
            textStorage.addAttribute(.strikethroughStyle, value: newStyle, range: subrange)
        }
        textStorage.endEditing()
        didChangeText()
    }
    
    func toggleUnderline(markdownMode: Bool) {
        if markdownMode {
            wrapSelectionWith(prefix: "<u>", suffix: "</u>")
            return
        }
        let range = selectedRange()
        guard let textStorage = self.textStorage else { return }
        if range.length == 0 {
            var attrs = typingAttributes
            let cur = (attrs[.underlineStyle] as? Int) ?? 0
            attrs[.underlineStyle] = cur == 0 ? NSUnderlineStyle.single.rawValue : 0
            typingAttributes = attrs
            return
        }
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.underlineStyle, in: range, options: []) { value, subrange, _ in
            let cur = (value as? Int) ?? 0
            let newStyle = cur == 0 ? NSUnderlineStyle.single.rawValue : 0
            textStorage.addAttribute(.underlineStyle, value: newStyle, range: subrange)
        }
        textStorage.endEditing()
        didChangeText()
    }
    
    func wrapSelectionWith(prefix: String, suffix: String) {
        let range = selectedRange()
        let fullText = (self.string as NSString)
        if range.length == 0 {
            insertText(prefix + suffix, replacementRange: range)
            setSelectedRange(NSRange(location: range.location + (prefix as NSString).length, length: 0))
            return
        }
        let selectedText = fullText.substring(with: range)
        if selectedText.hasPrefix(prefix) && selectedText.hasSuffix(suffix) && selectedText.count >= (prefix.count + suffix.count) {
            let startIndex = selectedText.index(selectedText.startIndex, offsetBy: prefix.count)
            let endIndex = selectedText.index(selectedText.endIndex, offsetBy: -suffix.count)
            let unwrapped = String(selectedText[startIndex..<endIndex])
            insertText(unwrapped, replacementRange: range)
        } else {
            insertText(prefix + selectedText + suffix, replacementRange: range)
        }
    }
    
    func applyFontFamily(_ name: String) {
        let range = selectedRange()
        guard let textStorage = self.textStorage else { return }
        if range.length == 0 {
            var attrs = typingAttributes
            let curSize = (attrs[.font] as? NSFont)?.pointSize ?? self.font?.pointSize ?? baseFontSize
            if let newFont = NSFont(name: name, size: curSize) {
                attrs[.font] = newFont
                typingAttributes = attrs
            }
            return
        }
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            let curSize = (value as? NSFont)?.pointSize ?? self.font?.pointSize ?? self.baseFontSize
            if let newFont = NSFont(name: name, size: curSize) {
                textStorage.addAttribute(.font, value: newFont, range: subrange)
            }
        }
        textStorage.endEditing()
        didChangeText()
    }
    
    func applyFontSize(_ size: CGFloat) {
        baseFontSize = size
        let range = selectedRange()
        guard let textStorage = self.textStorage else { return }
        if range.length == 0 {
            var attrs = typingAttributes
            let curName = (attrs[.font] as? NSFont)?.fontName ?? self.font?.fontName ?? "Consolas"
            if let newFont = NSFont(name: curName, size: size) {
                attrs[.font] = newFont
                typingAttributes = attrs
            }
            return
        }
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            let curName = (value as? NSFont)?.fontName ?? self.font?.fontName ?? "Consolas"
            if let newFont = NSFont(name: curName, size: size) {
                textStorage.addAttribute(.font, value: newFont, range: subrange)
            }
        }
        textStorage.endEditing()
        didChangeText()
    }
}
