import AppKit

protocol FormatToolbarDelegate: AnyObject {
    func formatDidSelectFontFamily(_ fontName: String)
    func formatDidSelectFontSize(_ size: CGFloat)
    func formatDidToggleBold()
    func formatDidToggleItalic()
    func formatDidToggleStrikethrough()
    func formatDidToggleUnderline()
    func formatDidToggleMarkdownMode(_ isMarkdown: Bool)
    func formatDidToggleTheme()
}

class FormatToolbarButton: NSButton {
    var isToggledOn: Bool = false {
        didSet {
            updateStyle()
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        wantsLayer = true
        isBordered = false
        layer?.cornerRadius = 3.0
        layer?.borderWidth = 1.0
        updateStyle()
    }
    
    func updateStyle() {
        let isDark = ThemeManager.shared.isDark
        let borderCol = isDark ? NSColor(calibratedWhite: 0.4, alpha: 1.0) : NSColor(calibratedWhite: 0.72, alpha: 1.0)
        let textCol = isDark ? NSColor.white : NSColor(calibratedWhite: 0.1, alpha: 1.0)
        
        if isToggledOn {
            let activeBg = isDark ? NSColor(calibratedRed: 0.20, green: 0.38, blue: 0.65, alpha: 1.0) : NSColor(calibratedRed: 0.78, green: 0.88, blue: 0.98, alpha: 1.0)
            layer?.backgroundColor = activeBg.cgColor
            layer?.borderColor = NSColor(calibratedRed: 0.10, green: 0.45, blue: 0.85, alpha: 1.0).cgColor
        } else {
            let normalBg = isDark ? NSColor(calibratedWhite: 0.25, alpha: 1.0) : NSColor(calibratedWhite: 0.98, alpha: 1.0)
            layer?.backgroundColor = normalBg.cgColor
            layer?.borderColor = borderCol.cgColor
        }
        
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: self.font ?? NSFont.systemFont(ofSize: 12),
            .foregroundColor: textCol,
            .paragraphStyle: pstyle
        ]
        self.attributedTitle = NSAttributedString(string: self.title, attributes: attrs)
        needsDisplay = true
    }
}

class FormatToolbar: NSView {
    weak var delegate: FormatToolbarDelegate?
    
    let fontPopup = NSPopUpButton()
    let sizePopup = NSPopUpButton()
    let boldButton = FormatToolbarButton()
    let italicButton = FormatToolbarButton()
    let strikeButton = FormatToolbarButton()
    let underlineButton = FormatToolbarButton()
    let markdownCheck = NSButton()
    let themeButton = FormatToolbarButton()
    
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
        applyTheme()
        
        // 1. Font Family Popup
        fontPopup.bezelStyle = .rounded
        fontPopup.font = ThemeManager.shared.uiFont(size: 11)
        let commonFonts = ["Consolas", "Menlo", "Courier New", "SF Pro", "Monaco", "Helvetica", "Arial", "Georgia", "Times New Roman"]
        for f in commonFonts {
            fontPopup.addItem(withTitle: f)
        }
        fontPopup.target = self
        fontPopup.action = #selector(onFontChanged)
        addSubview(fontPopup)
        
        // 2. Font Size Popup
        sizePopup.bezelStyle = .rounded
        sizePopup.font = ThemeManager.shared.uiFont(size: 11)
        let sizes = ["9", "10", "11", "12", "14", "16", "18", "20", "24", "28", "32", "36", "48"]
        for s in sizes {
            sizePopup.addItem(withTitle: s)
        }
        sizePopup.selectItem(withTitle: "14")
        sizePopup.target = self
        sizePopup.action = #selector(onSizeChanged)
        addSubview(sizePopup)
        
        // 3. Style Buttons (Bold, Italic, Strikethrough, Underline)
        setupStyleButton(boldButton, title: "B", font: NSFont.boldSystemFont(ofSize: 13), action: #selector(onBold), tooltip: "Negrita (Cmd+B)")
        
        let italicFont = NSFontManager.shared.convert(NSFont.systemFont(ofSize: 13), toHaveTrait: .italicFontMask)
        setupStyleButton(italicButton, title: "I", font: italicFont, action: #selector(onItalic), tooltip: "Cursiva (Cmd+I)")
        
        setupStyleButton(strikeButton, title: "S̶", font: NSFont.systemFont(ofSize: 13), action: #selector(onStrike), tooltip: "Tachada")
        
        setupStyleButton(underlineButton, title: "U̲", font: NSFont.systemFont(ofSize: 13), action: #selector(onUnderline), tooltip: "Subrayada (Cmd+U)")
        
        // 4. Markdown Mode Checkbox
        markdownCheck.setButtonType(.switch)
        markdownCheck.title = "Sintaxis Markdown (**)"
        markdownCheck.font = ThemeManager.shared.uiFont(size: 11)
        markdownCheck.toolTip = "Si está activo, Negrita, Cursiva y Tachado insertan marcas Markdown (**, *, ~~)"
        markdownCheck.target = self
        markdownCheck.action = #selector(onMarkdownToggled)
        addSubview(markdownCheck)
        
        // 5. Theme Toggle Button
        setupStyleButton(themeButton, title: ThemeManager.shared.isDark ? "☀️ Claro" : "🌙 Oscuro", font: ThemeManager.shared.uiFont(size: 11), action: #selector(onThemeToggle), tooltip: "Alternar entre Modo Claro y Oscuro (Cmd+Shift+D)")
        
        applyTheme()
    }
    
    private func setupStyleButton(_ button: FormatToolbarButton, title: String, font: NSFont, action: Selector, tooltip: String) {
        button.title = title
        button.font = font
        button.toolTip = tooltip
        button.target = self
        button.action = action
        addSubview(button)
    }
    
    func applyTheme() {
        let isDark = ThemeManager.shared.isDark
        layer?.backgroundColor = ThemeManager.shared.panelBackgroundColor.cgColor
        self.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
        
        fontPopup.appearance = self.appearance
        sizePopup.appearance = self.appearance
        
        boldButton.updateStyle()
        italicButton.updateStyle()
        strikeButton.updateStyle()
        underlineButton.updateStyle()
        
        markdownCheck.appearance = self.appearance
        markdownCheck.contentTintColor = isDark ? .white : NSColor(calibratedWhite: 0.1, alpha: 1.0)
        
        themeButton.title = isDark ? "☀️ Claro" : "🌙 Oscuro"
        themeButton.updateStyle()
        
        needsDisplay = true
    }
    
    override func layout() {
        super.layout()
        let h: CGFloat = 22
        let y: CGFloat = (bounds.height - h) / 2
        
        fontPopup.frame = NSRect(x: 10, y: y - 1, width: 130, height: h + 2)
        sizePopup.frame = NSRect(x: 145, y: y - 1, width: 62, height: h + 2)
        
        boldButton.frame = NSRect(x: 215, y: y, width: 30, height: h)
        italicButton.frame = NSRect(x: 249, y: y, width: 30, height: h)
        strikeButton.frame = NSRect(x: 283, y: y, width: 30, height: h)
        underlineButton.frame = NSRect(x: 317, y: y, width: 30, height: h)
        
        markdownCheck.frame = NSRect(x: 360, y: y + 1, width: 180, height: 20)
        
        let themeBtnW: CGFloat = 85
        themeButton.frame = NSRect(x: bounds.width - themeBtnW - 10, y: y, width: themeBtnW, height: h)
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
    
    @objc private func onFontChanged() {
        if let title = fontPopup.selectedItem?.title {
            delegate?.formatDidSelectFontFamily(title)
        }
    }
    
    @objc private func onSizeChanged() {
        if let title = sizePopup.selectedItem?.title, let size = Double(title) {
            delegate?.formatDidSelectFontSize(CGFloat(size))
        }
    }
    
    @objc private func onBold() { delegate?.formatDidToggleBold() }
    @objc private func onItalic() { delegate?.formatDidToggleItalic() }
    @objc private func onStrike() { delegate?.formatDidToggleStrikethrough() }
    @objc private func onUnderline() { delegate?.formatDidToggleUnderline() }
    @objc private func onMarkdownToggled() {
        delegate?.formatDidToggleMarkdownMode(markdownCheck.state == .on)
    }
    @objc private func onThemeToggle() {
        delegate?.formatDidToggleTheme()
    }
}
