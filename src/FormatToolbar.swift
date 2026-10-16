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
        layer?.cornerRadius = 4.0
        layer?.borderWidth = 1.0
        updateStyle()
    }
    
    func updateStyle() {
        let isDark = ThemeManager.shared.isDark
        let buttonTextCol: NSColor
        
        if isToggledOn {
            if isDark {
                // Modo Oscuro: El botón se pone en BLANCO con texto NEGRO intenso
                layer?.backgroundColor = NSColor(calibratedWhite: 0.96, alpha: 1.0).cgColor
                layer?.borderColor = NSColor.white.cgColor
                layer?.borderWidth = 1.5
                buttonTextCol = NSColor.black
            } else {
                // Modo Claro: El botón se oscurece a NEGRO con texto BLANCO
                layer?.backgroundColor = NSColor(calibratedWhite: 0.15, alpha: 1.0).cgColor
                layer?.borderColor = NSColor(calibratedWhite: 0.05, alpha: 1.0).cgColor
                layer?.borderWidth = 1.5
                buttonTextCol = NSColor.white
            }
        } else {
            layer?.borderWidth = 1.0
            if isDark {
                // Modo Oscuro inactivo: gris oscuro con texto blanco suave
                layer?.backgroundColor = NSColor(calibratedWhite: 0.22, alpha: 1.0).cgColor
                layer?.borderColor = NSColor(calibratedWhite: 0.38, alpha: 1.0).cgColor
                buttonTextCol = NSColor(calibratedWhite: 0.92, alpha: 1.0)
            } else {
                // Modo Claro inactivo: blanco/gris suave con texto oscuro
                layer?.backgroundColor = NSColor(calibratedWhite: 0.96, alpha: 1.0).cgColor
                layer?.borderColor = NSColor(calibratedWhite: 0.75, alpha: 1.0).cgColor
                buttonTextCol = NSColor(calibratedWhite: 0.15, alpha: 1.0)
            }
        }
        
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: self.font ?? NSFont.systemFont(ofSize: 12),
            .foregroundColor: buttonTextCol,
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
    
    func setStyleState(bold: Bool, italic: Bool, strikethrough: Bool, underline: Bool) {
        if boldButton.isToggledOn != bold { boldButton.isToggledOn = bold }
        if italicButton.isToggledOn != italic { italicButton.isToggledOn = italic }
        if strikeButton.isToggledOn != strikethrough { strikeButton.isToggledOn = strikethrough }
        if underlineButton.isToggledOn != underline { underlineButton.isToggledOn = underline }
    }
    
    @objc private func onBold() {
        boldButton.isToggledOn.toggle()
        delegate?.formatDidToggleBold()
    }
    
    @objc private func onItalic() {
        italicButton.isToggledOn.toggle()
        delegate?.formatDidToggleItalic()
    }
    
    @objc private func onStrike() {
        strikeButton.isToggledOn.toggle()
        delegate?.formatDidToggleStrikethrough()
    }
    
    @objc private func onUnderline() {
        underlineButton.isToggledOn.toggle()
        delegate?.formatDidToggleUnderline()
    }
    
    @objc private func onMarkdownToggled() {
        delegate?.formatDidToggleMarkdownMode(markdownCheck.state == .on)
    }
    
    @objc private func onThemeToggle() {
        delegate?.formatDidToggleTheme()
    }
}
