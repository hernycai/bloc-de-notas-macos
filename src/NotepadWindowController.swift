import AppKit
import UniformTypeIdentifiers

class NotepadWindowController: NSWindowController, NSWindowDelegate, InWindowMenuBarDelegate, NotepadTextViewDelegate, FindReplaceBarDelegate, FormatToolbarDelegate {
    
    var notepadDoc = NotepadDocument()
    
    private var inWindowMenuBar: InWindowMenuBar!
    var formatToolbar: FormatToolbar!
    private var findReplaceBar: FindReplaceBar!
    private var scrollView: NSScrollView!
    private var textView: NotepadTextView!
    private var statusBar: StatusBar!
    
    private weak var activeSavePanel: NSSavePanel?
    
    var isWordWrapActive: Bool {
        return textView?.isWordWrapEnabled ?? true
    }
    
    var isStatusBarActive: Bool {
        return !statusBar.isHidden
    }
    
    var isFormatBarActive: Bool {
        return !(formatToolbar?.isHidden ?? false)
    }
    
    convenience init() {
        let contentRect = NSRect(x: 150, y: 150, width: 850, height: 620)
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let window = NSWindow(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)
        self.init(window: window)
        window.delegate = self
        window.acceptsMouseMovedEvents = true
        setupUI()
        updateWindowTitle()
    }
    
    private func setupUI() {
        guard let window = self.window else { return }
        window.minSize = NSSize(width: 480, height: 300)
        window.appearance = NSAppearance(named: ThemeManager.shared.isDark ? .darkAqua : .aqua)
        
        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        contentView.wantsLayer = true
        contentView.autoresizingMask = [.width, .height]
        window.contentView = contentView
        
        // 1. In-Window Menu Bar
        inWindowMenuBar = InWindowMenuBar(frame: NSRect(x: 0, y: contentView.bounds.height - 28, width: contentView.bounds.width, height: 28))
        inWindowMenuBar.autoresizingMask = [.width, .minYMargin]
        inWindowMenuBar.delegate = self
        contentView.addSubview(inWindowMenuBar)
        
        // 2. Format Toolbar
        formatToolbar = FormatToolbar(frame: NSRect(x: 0, y: contentView.bounds.height - 28 - 32, width: contentView.bounds.width, height: 32))
        formatToolbar.autoresizingMask = [.width, .minYMargin]
        formatToolbar.delegate = self
        contentView.addSubview(formatToolbar)
        
        // 3. Find / Replace Bar (initially hidden)
        findReplaceBar = FindReplaceBar(frame: NSRect(x: 0, y: contentView.bounds.height - 28 - 32 - 36, width: contentView.bounds.width, height: 36))
        findReplaceBar.autoresizingMask = [.width, .minYMargin]
        findReplaceBar.delegate = self
        findReplaceBar.isHidden = true
        contentView.addSubview(findReplaceBar)
        
        // 4. Status Bar
        statusBar = StatusBar(frame: NSRect(x: 0, y: 0, width: contentView.bounds.width, height: 22))
        statusBar.autoresizingMask = [.width, .maxYMargin]
        contentView.addSubview(statusBar)
        
        // 5. ScrollView & TextView
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 22, width: contentView.bounds.width, height: contentView.bounds.height - 28 - 32 - 22))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = ThemeManager.shared.editorBackgroundColor
        
        let contentSize = scrollView.contentSize
        let config = EditorConfig.shared
        textView = NotepadTextView(contentSize: contentSize)
        textView.notepadDelegate = self
        textView.applyFontFamily(config.defaultFontFamily)
        textView.applyFontSize(config.defaultFontSize)
        textView.setWordWrap(config.defaultWordWrap)
        
        formatToolbar.isHidden = !config.showFormatBarByDefault
        statusBar.isHidden = !config.showStatusBarByDefault
        
        notepadDoc.lineEnding = config.defaultLineEnding
        notepadDoc.encoding = config.defaultEncoding
        statusBar.setLineEnding(notepadDoc.lineEnding)
        statusBar.setEncoding(notepadDoc.encodingName)
        
        NotificationCenter.default.addObserver(self, selector: #selector(configDidChange), name: .editorConfigDidChange, object: nil)
        
        scrollView.documentView = textView
        contentView.addSubview(scrollView)
        
        window.initialFirstResponder = textView
        relayoutViews()
    }
    
    @objc func configDidChange() {
        let config = EditorConfig.shared
        menuDidSelectTheme(config.themeMode)
        textView.applyFontFamily(config.defaultFontFamily)
        textView.applyFontSize(config.defaultFontSize)
        textView.setWordWrap(config.defaultWordWrap)
        formatToolbar.fontPopup.selectItem(withTitle: config.defaultFontFamily)
        formatToolbar.sizePopup.selectItem(withTitle: "\(Int(config.defaultFontSize))")
        statusBar.setLineEnding(config.defaultLineEnding)
        statusBar.setEncoding(config.defaultEncoding == .windowsCP1252 ? "ANSI (Windows-1252)" : "UTF-8")
        relayoutViews()
    }
    
    func focusEditor() {
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(textView)
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        focusEditor()
    }
    
    private func relayoutViews() {
        guard let contentView = window?.contentView else { return }
        let totalW = contentView.bounds.width
        let totalH = contentView.bounds.height
        
        let menuH: CGFloat = 28
        inWindowMenuBar.frame = NSRect(x: 0, y: totalH - menuH, width: totalW, height: menuH)
        
        let formatH: CGFloat = formatToolbar.isHidden ? 0 : 32
        if !formatToolbar.isHidden {
            formatToolbar.frame = NSRect(x: 0, y: totalH - menuH - formatH, width: totalW, height: formatH)
        }
        
        let findH: CGFloat = findReplaceBar.isHidden ? 0 : findReplaceBar.frame.height
        if !findReplaceBar.isHidden {
            findReplaceBar.frame = NSRect(x: 0, y: totalH - menuH - formatH - findH, width: totalW, height: findH)
        }
        
        let statusH: CGFloat = statusBar.isHidden ? 0 : 22
        if !statusBar.isHidden {
            statusBar.frame = NSRect(x: 0, y: 0, width: totalW, height: statusH)
        }
        
        let scrollY = statusH
        let scrollH = max(10, totalH - menuH - formatH - findH - statusH)
        scrollView.frame = NSRect(x: 0, y: scrollY, width: totalW, height: scrollH)
        
        contentView.needsDisplay = true
    }
    
    func updateWindowTitle() {
        window?.title = notepadDoc.windowTitle
    }
    
    func loadFile(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            var detectedEncoding: String.Encoding = .utf8
            var text: String?
            
            if let str = String(data: data, encoding: .utf8) {
                text = str
                detectedEncoding = .utf8
            } else if let str = String(data: data, encoding: .windowsCP1252) {
                text = str
                detectedEncoding = .windowsCP1252
            } else if let str = String(data: data, encoding: .isoLatin1) {
                text = str
                detectedEncoding = .isoLatin1
            } else {
                text = String(decoding: data, as: UTF8.self)
            }
            
            let loadedText = text ?? ""
            notepadDoc.fileURL = url
            notepadDoc.encoding = detectedEncoding
            notepadDoc.lineEnding = notepadDoc.detectLineEnding(in: loadedText)
            notepadDoc.isDirty = false
            
            textView.string = loadedText
            textView.undoManager?.removeAllActions()
            
            statusBar.setLineEnding(notepadDoc.lineEnding)
            statusBar.setEncoding(notepadDoc.encodingName)
            
            if url.pathExtension.lowercased() == "md" {
                formatToolbar.markdownCheck.state = .on
            } else {
                formatToolbar.markdownCheck.state = .off
            }
            
            updateWindowTitle()
            textView.updateCursorPosition()
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
    
    // MARK: - Save and Open Flows
    
    func confirmUnsavedChanges(completion: @escaping (Bool) -> Void) {
        guard notepadDoc.isDirty else {
            completion(true)
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Bloc de notas"
        alert.informativeText = "¿Desea guardar los cambios en \(notepadDoc.displayName)?"
        alert.addButton(withTitle: "Guardar")
        alert.addButton(withTitle: "No guardar")
        alert.addButton(withTitle: "Cancelar")
        
        alert.beginSheetModal(for: window!) { response in
            switch response {
            case .alertFirstButtonReturn: // Guardar
                self.menuDidSelectSave()
                completion(!self.notepadDoc.isDirty)
            case .alertSecondButtonReturn: // No guardar
                completion(true)
            default: // Cancelar
                completion(false)
            }
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if notepadDoc.isDirty {
            confirmUnsavedChanges { canClose in
                if canClose {
                    self.notepadDoc.isDirty = false
                    self.window?.close()
                }
            }
            return false
        }
        return true
    }
    
    // MARK: - NotepadTextViewDelegate
    
    func textViewDidChangeCursorPosition(line: Int, column: Int) {
        statusBar.setCursorPosition(line: line, column: column)
    }
    
    func textViewDidChangeContent() {
        if !notepadDoc.isDirty {
            notepadDoc.isDirty = true
            updateWindowTitle()
        }
    }
    
    func textViewDidRequestOpenURL(_ url: URL) {
        confirmUnsavedChanges { canOpen in
            if canOpen {
                self.loadFile(url: url)
            }
        }
    }
    
    // MARK: - InWindowMenuBarDelegate
    
    func menuDidSelectNew() {
        confirmUnsavedChanges { canProceed in
            if canProceed {
                self.notepadDoc = NotepadDocument()
                self.textView.string = ""
                self.textView.undoManager?.removeAllActions()
                self.statusBar.setLineEnding(self.notepadDoc.lineEnding)
                self.statusBar.setEncoding(self.notepadDoc.encodingName)
                self.formatToolbar.markdownCheck.state = .off
                self.updateWindowTitle()
                self.textView.updateCursorPosition()
            }
        }
    }
    
    func menuDidSelectNewWindow() {
        let appDelegate = NSApp.delegate as? AppDelegate
        appDelegate?.createNewWindow()
    }
    
    func menuDidSelectOpen() {
        confirmUnsavedChanges { canProceed in
            guard canProceed else { return }
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            let mdType = UTType(filenameExtension: "md") ?? .plainText
            panel.allowedContentTypes = [.plainText, mdType, .text]
            panel.allowsOtherFileTypes = true
            panel.beginSheetModal(for: self.window!) { response in
                if response == .OK, let url = panel.url {
                    self.loadFile(url: url)
                }
            }
        }
    }
    
    func menuDidSelectSave() {
        if let url = notepadDoc.fileURL {
            saveToFile(url: url)
        } else {
            menuDidSelectSaveAs()
        }
    }
    
    func menuDidSelectSaveAs() {
        let panel = NSSavePanel()
        let txtType = UTType.plainText
        let mdType = UTType(filenameExtension: "md") ?? .plainText
        
        let isCurrentMd = notepadDoc.fileURL?.pathExtension.lowercased() == "md" || formatToolbar.markdownCheck.state == .on
        let defaultName = notepadDoc.fileURL?.lastPathComponent ?? (isCurrentMd ? "Documento.md" : "Documento.txt")
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = isCurrentMd ? [mdType, txtType] : [txtType, mdType]
        panel.allowsOtherFileTypes = true
        
        // Accessory view with format picker
        let accessory = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 32))
        let label = NSTextField(labelWithString: "Formato:")
        label.frame = NSRect(x: 0, y: 6, width: 60, height: 20)
        label.font = ThemeManager.shared.uiFont(size: 12)
        
        let formatPopup = NSPopUpButton(frame: NSRect(x: 65, y: 4, width: 245, height: 24))
        formatPopup.addItem(withTitle: "Documento de texto (*.txt)")
        formatPopup.addItem(withTitle: "Archivo Markdown (*.md)")
        formatPopup.selectItem(at: isCurrentMd ? 1 : 0)
        
        accessory.addSubview(label)
        accessory.addSubview(formatPopup)
        panel.accessoryView = accessory
        
        formatPopup.target = self
        formatPopup.action = #selector(saveFormatChanged(_:))
        self.activeSavePanel = panel
        
        panel.beginSheetModal(for: window!) { response in
            self.activeSavePanel = nil
            if response == .OK, let url = panel.url {
                self.saveToFile(url: url)
                if url.pathExtension.lowercased() == "md" {
                    self.formatToolbar.markdownCheck.state = .on
                }
            }
        }
    }
    
    @objc private func saveFormatChanged(_ sender: NSPopUpButton) {
        guard let panel = activeSavePanel else { return }
        let txtType = UTType.plainText
        let mdType = UTType(filenameExtension: "md") ?? .plainText
        
        var currentName = panel.nameFieldStringValue
        if sender.indexOfSelectedItem == 1 {
            // Markdown
            panel.allowedContentTypes = [mdType, txtType]
            if currentName.hasSuffix(".txt") {
                currentName = String(currentName.dropLast(4)) + ".md"
                panel.nameFieldStringValue = currentName
            } else if !currentName.hasSuffix(".md") {
                panel.nameFieldStringValue = currentName + ".md"
            }
        } else {
            // Text
            panel.allowedContentTypes = [txtType, mdType]
            if currentName.hasSuffix(".md") {
                currentName = String(currentName.dropLast(3)) + ".txt"
                panel.nameFieldStringValue = currentName
            } else if !currentName.hasSuffix(".txt") {
                panel.nameFieldStringValue = currentName + ".txt"
            }
        }
    }
    
    private func saveToFile(url: URL) {
        var text = textView.string
        if notepadDoc.lineEnding == .crlf {
            text = text.replacingOccurrences(of: "\r\n", with: "\n")
            text = text.replacingOccurrences(of: "\n", with: "\r\n")
        }
        
        let data = text.data(using: notepadDoc.encoding) ?? text.data(using: .utf8) ?? Data()
        do {
            try data.write(to: url)
            notepadDoc.fileURL = url
            notepadDoc.isDirty = false
            updateWindowTitle()
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
    
    func menuDidSelectPrint() {
        let printInfo = NSPrintInfo.shared
        let printOp = NSPrintOperation(view: textView, printInfo: printInfo)
        printOp.run()
    }
    
    func menuDidSelectExit() {
        window?.performClose(nil)
    }
    
    func menuDidSelectUndo() { textView.undoManager?.undo() }
    func menuDidSelectRedo() { textView.undoManager?.redo() }
    func menuDidSelectCut() { textView.cut(nil) }
    func menuDidSelectCopy() { textView.copy(nil) }
    func menuDidSelectPaste() { textView.paste(nil) }
    func menuDidSelectDelete() { textView.delete(nil) }
    
    func menuDidSelectFind() {
        findReplaceBar.isHidden = false
        findReplaceBar.focus(replaceMode: false)
        relayoutViews()
    }
    
    func menuDidSelectFindNext() {
        if findReplaceBar.isHidden {
            menuDidSelectFind()
        } else {
            findReplaceBar.focus(replaceMode: findReplaceBar.isReplaceMode)
        }
    }
    
    func menuDidSelectFindPrevious() {
        if findReplaceBar.isHidden {
            menuDidSelectFind()
        }
    }
    
    func menuDidSelectReplace() {
        findReplaceBar.isHidden = false
        findReplaceBar.focus(replaceMode: true)
        relayoutViews()
    }
    
    func menuDidSelectGoToLine() {
        let lines = textView.string.components(separatedBy: "\n")
        let totalLines = max(1, lines.count)
        let curPos = textView.selectedRange().location
        let textBefore = (textView.string as NSString).substring(to: min(curPos, (textView.string as NSString).length))
        let curLine = textBefore.components(separatedBy: "\n").count
        
        GoToLineDialog.show(in: window!, currentLine: curLine, maxLine: totalLines) { targetLine in
            guard let line = targetLine else { return }
            self.jumpToLine(line)
        }
    }
    
    private func jumpToLine(_ targetLine: Int) {
        let lines = textView.string.components(separatedBy: "\n")
        let clamped = min(max(1, targetLine), lines.count)
        var offset = 0
        for i in 0..<(clamped - 1) {
            offset += (lines[i] as NSString).length + 1
        }
        let range = NSRange(location: offset, length: 0)
        textView.setSelectedRange(range)
        textView.scrollRangeToVisible(range)
        textView.updateCursorPosition()
    }
    
    func menuDidSelectSelectAll() { textView.selectAll(nil) }
    func menuDidSelectTimeDate() { textView.insertTimeDate() }
    
    func menuDidToggleWordWrap() {
        let newState = !textView.isWordWrapEnabled
        textView.setWordWrap(newState)
    }
    
    func menuDidSelectFont() {
        NSFontManager.shared.target = self
        NSFontManager.shared.action = #selector(changeFont(_:))
        NSFontPanel.shared.makeKeyAndOrderFront(nil)
    }
    
    @objc func changeFont(_ sender: Any?) {
        guard let currentFont = textView.font else { return }
        let newFont = NSFontManager.shared.convert(currentFont)
        textView.font = newFont
        textView.baseFontSize = newFont.pointSize
        formatToolbar.fontPopup.selectItem(withTitle: newFont.fontName)
        formatToolbar.sizePopup.selectItem(withTitle: "\(Int(newFont.pointSize))")
    }
    
    func menuDidZoomIn() {
        if textView.zoomPercentage < 500 {
            textView.zoomPercentage += 10
            textView.updateFontZoom()
            statusBar.setZoom(percentage: textView.zoomPercentage)
        }
    }
    
    func menuDidZoomOut() {
        if textView.zoomPercentage > 20 {
            textView.zoomPercentage -= 10
            textView.updateFontZoom()
            statusBar.setZoom(percentage: textView.zoomPercentage)
        }
    }
    
    func menuDidResetZoom() {
        textView.zoomPercentage = 100
        textView.updateFontZoom()
        statusBar.setZoom(percentage: 100)
    }
    
    func menuDidToggleStatusBar() {
        statusBar.isHidden = !statusBar.isHidden
        relayoutViews()
    }
    
    func menuDidToggleFormatBar() {
        formatToolbar.isHidden = !formatToolbar.isHidden
        relayoutViews()
    }
    
    func menuDidSelectTheme(_ mode: NotepadThemeMode) {
        ThemeManager.shared.currentMode = mode
        window?.appearance = NSAppearance(named: ThemeManager.shared.isDark ? .darkAqua : .aqua)
        inWindowMenuBar.applyTheme()
        formatToolbar.applyTheme()
        findReplaceBar.applyTheme()
        statusBar.applyTheme()
        textView.applyTheme()
        scrollView.backgroundColor = ThemeManager.shared.editorBackgroundColor
        contentView?.needsDisplay = true
    }
    
    private var contentView: NSView? { return window?.contentView }
    
    func menuDidSelectHelp() {
        if let url = URL(string: "https://support.microsoft.com/es-es/windows/ayuda-en-el-bloc-de-notas-4d680ff9-cc77-f213-b564-927cb7041477") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func menuDidSelectAbout() {
        AboutDialog.show(in: window!)
    }
    
    func menuDidSelectSettings() {
        SettingsWindowController.shared.showSettings()
    }
    
    func menuDidCheckUpdates() {
        AppUpdater.shared.checkForUpdates(in: window, userInitiated: true)
    }
    
    // MARK: - FormatToolbarDelegate
    
    func formatDidSelectFontFamily(_ fontName: String) {
        textView.applyFontFamily(fontName)
    }
    
    func formatDidSelectFontSize(_ size: CGFloat) {
        textView.applyFontSize(size)
    }
    
    func formatDidToggleBold() {
        textView.toggleBold(markdownMode: formatToolbar.markdownCheck.state == .on)
    }
    
    func formatDidToggleItalic() {
        textView.toggleItalic(markdownMode: formatToolbar.markdownCheck.state == .on)
    }
    
    func formatDidToggleStrikethrough() {
        textView.toggleStrikethrough(markdownMode: formatToolbar.markdownCheck.state == .on)
    }
    
    func formatDidToggleUnderline() {
        textView.toggleUnderline(markdownMode: formatToolbar.markdownCheck.state == .on)
    }
    
    func formatDidToggleMarkdownMode(_ isMarkdown: Bool) {
        // State is checked directly in toggle methods
    }
    
    func formatDidToggleTheme() {
        ThemeManager.shared.toggleTheme()
        menuDidSelectTheme(ThemeManager.shared.currentMode)
    }
    
    // MARK: - FindReplaceBarDelegate
    
    func findText(_ text: String, forward: Bool, matchCase: Bool) {
        let fullText = textView.string as NSString
        let curRange = textView.selectedRange()
        var options: NSString.CompareOptions = []
        if !matchCase { options.insert(.caseInsensitive) }
        
        let searchRange: NSRange
        if forward {
            let start = curRange.location + curRange.length
            if start < fullText.length {
                searchRange = NSRange(location: start, length: fullText.length - start)
            } else {
                searchRange = NSRange(location: 0, length: fullText.length)
            }
        } else {
            let end = curRange.location
            searchRange = NSRange(location: 0, length: max(0, end))
            options.insert(.backwards)
        }
        
        var match = fullText.range(of: text, options: options, range: searchRange)
        if match.location == NSNotFound && searchRange.location != 0 {
            let wrapRange = NSRange(location: 0, length: fullText.length)
            match = fullText.range(of: text, options: options, range: wrapRange)
        }
        
        if match.location != NSNotFound {
            textView.setSelectedRange(match)
            textView.scrollRangeToVisible(match)
            textView.updateCursorPosition()
        } else {
            NSSound.beep()
        }
    }
    
    func replaceCurrent(with replacement: String) {
        let selectedRange = textView.selectedRange()
        guard selectedRange.length > 0 else { return }
        textView.insertText(replacement, replacementRange: selectedRange)
    }
    
    func replaceAll(search: String, replacement: String, matchCase: Bool) {
        let options: NSString.CompareOptions = matchCase ? [] : [.caseInsensitive]
        let currentString = textView.string
        let newString = (currentString as NSString).replacingOccurrences(of: search, with: replacement, options: options, range: NSRange(location: 0, length: (currentString as NSString).length))
        textView.string = newString
        textView.didChangeText()
    }
    
    func closeFindReplace() {
        findReplaceBar.isHidden = true
        relayoutViews()
        window?.makeFirstResponder(textView)
    }
}
