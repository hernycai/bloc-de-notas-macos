import AppKit

protocol FindReplaceBarDelegate: AnyObject {
    func findText(_ text: String, forward: Bool, matchCase: Bool)
    func replaceCurrent(with replacement: String)
    func replaceAll(search: String, replacement: String, matchCase: Bool)
    func closeFindReplace()
}

class FindReplaceBar: NSView, NSTextFieldDelegate, NSSearchFieldDelegate {
    weak var delegate: FindReplaceBarDelegate?
    
    private let findField = NSSearchField()
    private let replaceField = NSTextField()
    private let findNextBtn = NSButton()
    private let findPrevBtn = NSButton()
    private let replaceBtn = NSButton()
    private let replaceAllBtn = NSButton()
    private let matchCaseCheck = NSButton()
    private let closeBtn = NSButton()
    
    var isReplaceMode: Bool = false {
        didSet {
            updateMode()
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = ThemeManager.shared.panelBackgroundColor.cgColor
        
        findField.placeholderString = "Buscar..."
        findField.font = ThemeManager.shared.uiFont(size: 12)
        findField.delegate = self
        findField.target = self
        findField.action = #selector(onFindNext)
        addSubview(findField)
        
        replaceField.placeholderString = "Reemplazar por..."
        replaceField.font = ThemeManager.shared.uiFont(size: 12)
        replaceField.delegate = self
        addSubview(replaceField)
        
        setupButton(findNextBtn, title: "Siguiente", action: #selector(onFindNext))
        setupButton(findPrevBtn, title: "Anterior", action: #selector(onFindPrev))
        setupButton(replaceBtn, title: "Reemplazar", action: #selector(onReplace))
        setupButton(replaceAllBtn, title: "Reemplazar todo", action: #selector(onReplaceAll))
        
        matchCaseCheck.setButtonType(.switch)
        matchCaseCheck.title = "Mayús./minús."
        matchCaseCheck.font = ThemeManager.shared.uiFont(size: 11)
        addSubview(matchCaseCheck)
        
        closeBtn.title = "✕"
        closeBtn.isBordered = false
        closeBtn.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        closeBtn.target = self
        closeBtn.action = #selector(onClose)
        addSubview(closeBtn)
        
        updateMode()
    }
    
    private func setupButton(_ btn: NSButton, title: String, action: Selector) {
        btn.title = title
        btn.bezelStyle = .rounded
        btn.font = ThemeManager.shared.uiFont(size: 11)
        btn.target = self
        btn.action = action
        addSubview(btn)
    }
    
    func applyTheme() {
        layer?.backgroundColor = ThemeManager.shared.panelBackgroundColor.cgColor
        needsDisplay = true
    }
    
    func focus(replaceMode: Bool = false) {
        self.isReplaceMode = replaceMode
        window?.makeFirstResponder(findField)
    }
    
    private func updateMode() {
        replaceField.isHidden = !isReplaceMode
        replaceBtn.isHidden = !isReplaceMode
        replaceAllBtn.isHidden = !isReplaceMode
        
        let desiredHeight: CGFloat = isReplaceMode ? 68 : 36
        if frame.height != desiredHeight {
            frame.size.height = desiredHeight
            superview?.needsLayout = true
        }
        needsLayout = true
    }
    
    override func layout() {
        super.layout()
        let w = bounds.width
        closeBtn.frame = NSRect(x: w - 28, y: bounds.height - 28, width: 22, height: 22)
        
        if isReplaceMode {
            // Row 1 (Search)
            findField.frame = NSRect(x: 12, y: bounds.height - 30, width: 200, height: 22)
            findNextBtn.frame = NSRect(x: 218, y: bounds.height - 32, width: 80, height: 24)
            findPrevBtn.frame = NSRect(x: 302, y: bounds.height - 32, width: 80, height: 24)
            matchCaseCheck.frame = NSRect(x: 390, y: bounds.height - 30, width: 120, height: 20)
            
            // Row 2 (Replace)
            replaceField.frame = NSRect(x: 12, y: 6, width: 200, height: 22)
            replaceBtn.frame = NSRect(x: 218, y: 4, width: 95, height: 24)
            replaceAllBtn.frame = NSRect(x: 317, y: 4, width: 120, height: 24)
        } else {
            findField.frame = NSRect(x: 12, y: 7, width: 220, height: 22)
            findNextBtn.frame = NSRect(x: 238, y: 5, width: 80, height: 24)
            findPrevBtn.frame = NSRect(x: 322, y: 5, width: 80, height: 24)
            matchCaseCheck.frame = NSRect(x: 410, y: 7, width: 120, height: 20)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        ThemeManager.shared.separatorColor.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: 0.5))
        path.line(to: NSPoint(x: bounds.width, y: 0.5))
        path.lineWidth = 1.0
        path.stroke()
    }
    
    @objc private func onFindNext() {
        let text = findField.stringValue
        guard !text.isEmpty else { return }
        delegate?.findText(text, forward: true, matchCase: matchCaseCheck.state == .on)
    }
    
    @objc private func onFindPrev() {
        let text = findField.stringValue
        guard !text.isEmpty else { return }
        delegate?.findText(text, forward: false, matchCase: matchCaseCheck.state == .on)
    }
    
    @objc private func onReplace() {
        delegate?.replaceCurrent(with: replaceField.stringValue)
        onFindNext()
    }
    
    @objc private func onReplaceAll() {
        let text = findField.stringValue
        guard !text.isEmpty else { return }
        delegate?.replaceAll(search: text, replacement: replaceField.stringValue, matchCase: matchCaseCheck.state == .on)
    }
    
    @objc private func onClose() {
        delegate?.closeFindReplace()
    }
    
    override func cancelOperation(_ sender: Any?) {
        onClose()
    }
}
