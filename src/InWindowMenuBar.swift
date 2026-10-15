import AppKit

protocol InWindowMenuBarDelegate: AnyObject {
    func menuDidSelectNew()
    func menuDidSelectNewWindow()
    func menuDidSelectOpen()
    func menuDidSelectSave()
    func menuDidSelectSaveAs()
    func menuDidSelectPrint()
    func menuDidSelectExit()
    
    func menuDidSelectUndo()
    func menuDidSelectRedo()
    func menuDidSelectCut()
    func menuDidSelectCopy()
    func menuDidSelectPaste()
    func menuDidSelectDelete()
    func menuDidSelectFind()
    func menuDidSelectFindNext()
    func menuDidSelectFindPrevious()
    func menuDidSelectReplace()
    func menuDidSelectGoToLine()
    func menuDidSelectSelectAll()
    func menuDidSelectTimeDate()
    
    func menuDidToggleWordWrap()
    func menuDidSelectFont()
    func formatDidToggleBold()
    func formatDidToggleItalic()
    func formatDidToggleUnderline()
    func formatDidToggleStrikethrough()
    
    func menuDidZoomIn()
    func menuDidZoomOut()
    func menuDidResetZoom()
    func menuDidToggleStatusBar()
    func menuDidToggleFormatBar()
    func menuDidSelectTheme(_ mode: NotepadThemeMode)
    
    func menuDidSelectHelp()
    func menuDidSelectAbout()
    func menuDidSelectSettings()
    func menuDidCheckUpdates()
    
    var isWordWrapActive: Bool { get }
    var isStatusBarActive: Bool { get }
    var isFormatBarActive: Bool { get }
}

class WindowsMenuButton: NSButton {
    weak var menuBar: InWindowMenuBar?
    private var trackingArea: NSTrackingArea?
    
    var isSelectedMenu: Bool = false {
        didSet {
            updateButtonAppearance()
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        addTrackingArea(area)
        self.trackingArea = area
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        layer?.backgroundColor = ThemeManager.shared.menuBarHoverColor.cgColor
        menuBar?.buttonMouseEntered(self)
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        updateButtonAppearance()
    }
    
    func updateButtonAppearance() {
        if isSelectedMenu {
            layer?.backgroundColor = ThemeManager.shared.menuBarHoverColor.cgColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
}

class InWindowMenuBar: NSView {
    weak var delegate: InWindowMenuBarDelegate?
    
    private var buttons: [WindowsMenuButton] = []
    private let dropdownPanel = WindowsDropdownPanel()
    private var activeMenuTag: Int? = nil
    private var clickMonitor: Any?
    private let themeBarButton = WindowsMenuButton()
    private let settingsBarButton = WindowsMenuButton()
    
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
        layer?.backgroundColor = ThemeManager.shared.menuBarBackgroundColor.cgColor
        
        dropdownPanel.onDismiss = { [weak self] in
            self?.closeDropdown()
        }
        dropdownPanel.onNavigate = { [weak self] left in
            self?.navigateMenu(left: left)
        }
        
        let titles = ["Archivo", "Edición", "Formato", "Ver", "Ayuda"]
        var xOffset: CGFloat = 8.0
        
        for (index, title) in titles.enumerated() {
            let button = WindowsMenuButton(frame: NSRect(x: xOffset, y: 2, width: 62, height: 24))
            button.title = title
            button.isBordered = false
            button.bezelStyle = .regularSquare
            button.font = ThemeManager.shared.uiFont(size: 12)
            button.tag = index
            button.menuBar = self
            button.target = self
            button.action = #selector(menuButtonClicked(_:))
            button.wantsLayer = true
            button.layer?.cornerRadius = 3.0
            button.contentTintColor = ThemeManager.shared.menuBarTextColor
            
            let size = (title as NSString).size(withAttributes: [.font: button.font!])
            button.frame.size.width = size.width + 16.0
            
            addSubview(button)
            buttons.append(button)
            
            xOffset += button.frame.width + 2.0
        }
        
        // Quick Theme Toggle on the right
        themeBarButton.title = ThemeManager.shared.isDark ? "☀️" : "🌙"
        themeBarButton.toolTip = "Alternar entre modo claro y oscuro (Cmd+Shift+D)"
        themeBarButton.isBordered = false
        themeBarButton.font = NSFont.systemFont(ofSize: 13)
        themeBarButton.target = self
        themeBarButton.action = #selector(themeBarButtonClicked)
        themeBarButton.wantsLayer = true
        themeBarButton.layer?.cornerRadius = 3.0
        addSubview(themeBarButton)
        
        // Settings Button on the right
        settingsBarButton.title = "⚙️"
        settingsBarButton.toolTip = "Configuración (Cmd+,)"
        settingsBarButton.isBordered = false
        settingsBarButton.font = NSFont.systemFont(ofSize: 13)
        settingsBarButton.target = self
        settingsBarButton.action = #selector(settingsBarButtonClicked)
        settingsBarButton.wantsLayer = true
        settingsBarButton.layer?.cornerRadius = 3.0
        addSubview(settingsBarButton)
    }
    
    override func layout() {
        super.layout()
        settingsBarButton.frame = NSRect(x: bounds.width - 34, y: 2, width: 28, height: 24)
        themeBarButton.frame = NSRect(x: bounds.width - 64, y: 2, width: 28, height: 24)
    }
    
    @objc private func themeBarButtonClicked() {
        ThemeManager.shared.toggleTheme()
        delegate?.menuDidSelectTheme(ThemeManager.shared.currentMode)
    }
    
    @objc private func settingsBarButtonClicked() {
        delegate?.menuDidSelectSettings()
    }
    
    func applyTheme() {
        layer?.backgroundColor = ThemeManager.shared.menuBarBackgroundColor.cgColor
        for button in buttons {
            button.contentTintColor = ThemeManager.shared.menuBarTextColor
            button.updateButtonAppearance()
        }
        themeBarButton.title = ThemeManager.shared.isDark ? "☀️" : "🌙"
        themeBarButton.updateButtonAppearance()
        settingsBarButton.updateButtonAppearance()
        needsDisplay = true
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
    
    @objc private func menuButtonClicked(_ sender: WindowsMenuButton) {
        if activeMenuTag == sender.tag {
            closeDropdown()
        } else {
            openDropdown(tag: sender.tag)
        }
    }
    
    func buttonMouseEntered(_ button: WindowsMenuButton) {
        // If a menu is currently open, gliding cursor to another button opens it immediately!
        if activeMenuTag != nil && activeMenuTag != button.tag {
            openDropdown(tag: button.tag)
        }
    }
    
    func openDropdown(tag: Int) {
        activeMenuTag = tag
        for btn in buttons {
            btn.isSelectedMenu = (btn.tag == tag)
        }
        
        guard let button = buttons.first(where: { $0.tag == tag }),
              let window = self.window else { return }
        
        let screenRect = window.convertToScreen(button.convert(button.bounds, to: nil))
        let origin = NSPoint(x: screenRect.origin.x, y: screenRect.origin.y)
        
        let items: [MenuItemModel]
        let width: CGFloat
        switch tag {
        case 0:
            items = buildFileItems()
            width = 220
        case 1:
            items = buildEditItems()
            width = 230
        case 2:
            items = buildFormatItems()
            width = 200
        case 3:
            items = buildViewItems()
            width = 230
        case 4:
            items = buildHelpItems()
            width = 210
        default:
            return
        }
        
        dropdownPanel.show(items: items, at: origin, width: width)
        startOutsideClickMonitor()
    }
    
    func closeDropdown() {
        activeMenuTag = nil
        for btn in buttons {
            btn.isSelectedMenu = false
        }
        dropdownPanel.orderOut(nil)
        stopOutsideClickMonitor()
    }
    
    private func navigateMenu(left: Bool) {
        guard let current = activeMenuTag else { return }
        let next = left ? (current - 1 + buttons.count) % buttons.count : (current + 1) % buttons.count
        openDropdown(tag: next)
    }
    
    private func startOutsideClickMonitor() {
        stopOutsideClickMonitor()
        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.activeMenuTag != nil else { return event }
            
            let clickLoc = NSEvent.mouseLocation
            
            // Check if clicked inside dropdown
            if self.dropdownPanel.frame.contains(clickLoc) {
                return event
            }
            
            // Check if clicked inside menu bar buttons
            if let window = self.window {
                let barScreenRect = window.convertToScreen(self.convert(self.bounds, to: nil))
                if barScreenRect.contains(clickLoc) {
                    return event
                }
            }
            
            // Clicked outside: close dropdown!
            self.closeDropdown()
            return event
        }
    }
    
    private func stopOutsideClickMonitor() {
        if let mon = clickMonitor {
            NSEvent.removeMonitor(mon)
            clickMonitor = nil
        }
    }
    
    // MARK: - Menu Items Builders
    
    private func buildFileItems() -> [MenuItemModel] {
        return [
            .item("Nuevo", shortcut: "Ctrl+N") { [weak self] in self?.delegate?.menuDidSelectNew() },
            .item("Nueva ventana", shortcut: "Ctrl+Shift+N") { [weak self] in self?.delegate?.menuDidSelectNewWindow() },
            .item("Abrir...", shortcut: "Ctrl+O") { [weak self] in self?.delegate?.menuDidSelectOpen() },
            .item("Guardar", shortcut: "Ctrl+S") { [weak self] in self?.delegate?.menuDidSelectSave() },
            .item("Guardar como...", shortcut: "Ctrl+Shift+S") { [weak self] in self?.delegate?.menuDidSelectSaveAs() },
            .separator(),
            .item("Configuración", shortcut: "Ctrl+,") { [weak self] in self?.delegate?.menuDidSelectSettings() },
            .separator(),
            .item("Imprimir...", shortcut: "Ctrl+P") { [weak self] in self?.delegate?.menuDidSelectPrint() },
            .separator(),
            .item("Salir", shortcut: "Ctrl+Q") { [weak self] in self?.delegate?.menuDidSelectExit() }
        ]
    }
    
    private func buildEditItems() -> [MenuItemModel] {
        return [
            .item("Deshacer", shortcut: "Ctrl+Z") { [weak self] in self?.delegate?.menuDidSelectUndo() },
            .item("Rehacer", shortcut: "Ctrl+Shift+Z") { [weak self] in self?.delegate?.menuDidSelectRedo() },
            .separator(),
            .item("Cortar", shortcut: "Ctrl+X") { [weak self] in self?.delegate?.menuDidSelectCut() },
            .item("Copiar", shortcut: "Ctrl+C") { [weak self] in self?.delegate?.menuDidSelectCopy() },
            .item("Pegar", shortcut: "Ctrl+V") { [weak self] in self?.delegate?.menuDidSelectPaste() },
            .item("Eliminar", shortcut: "Supr") { [weak self] in self?.delegate?.menuDidSelectDelete() },
            .separator(),
            .item("Buscar...", shortcut: "Ctrl+F") { [weak self] in self?.delegate?.menuDidSelectFind() },
            .item("Buscar siguiente", shortcut: "F3") { [weak self] in self?.delegate?.menuDidSelectFindNext() },
            .item("Buscar anterior", shortcut: "Shift+F3") { [weak self] in self?.delegate?.menuDidSelectFindPrevious() },
            .item("Reemplazar...", shortcut: "Ctrl+H") { [weak self] in self?.delegate?.menuDidSelectReplace() },
            .item("Ir a...", shortcut: "Ctrl+L") { [weak self] in self?.delegate?.menuDidSelectGoToLine() },
            .separator(),
            .item("Seleccionar todo", shortcut: "Ctrl+A") { [weak self] in self?.delegate?.menuDidSelectSelectAll() },
            .item("Hora y fecha", shortcut: "F5") { [weak self] in self?.delegate?.menuDidSelectTimeDate() }
        ]
    }
    
    private func buildFormatItems() -> [MenuItemModel] {
        return [
            .item("Negrita", shortcut: "Ctrl+B") { [weak self] in self?.delegate?.formatDidToggleBold() },
            .item("Cursiva", shortcut: "Ctrl+I") { [weak self] in self?.delegate?.formatDidToggleItalic() },
            .item("Subrayado", shortcut: "Ctrl+U") { [weak self] in self?.delegate?.formatDidToggleUnderline() },
            .item("Tachado") { [weak self] in self?.delegate?.formatDidToggleStrikethrough() },
            .separator(),
            .item("Ajuste de línea", isChecked: delegate?.isWordWrapActive ?? true) { [weak self] in self?.delegate?.menuDidToggleWordWrap() },
            .item("Fuente...", shortcut: "Ctrl+T") { [weak self] in self?.delegate?.menuDidSelectFont() }
        ]
    }
    
    private func buildViewItems() -> [MenuItemModel] {
        return [
            .item("Acercar zoom", shortcut: "Ctrl++") { [weak self] in self?.delegate?.menuDidZoomIn() },
            .item("Alejar zoom", shortcut: "Ctrl+-") { [weak self] in self?.delegate?.menuDidZoomOut() },
            .item("Restaurar zoom", shortcut: "Ctrl+0") { [weak self] in self?.delegate?.menuDidResetZoom() },
            .separator(),
            .item("Barra de estado", isChecked: delegate?.isStatusBarActive ?? true) { [weak self] in self?.delegate?.menuDidToggleStatusBar() },
            .item("Barra de formato", isChecked: delegate?.isFormatBarActive ?? true) { [weak self] in self?.delegate?.menuDidToggleFormatBar() },
            .separator(),
            .item("Tema: Windows Clásico (Claro)", isChecked: ThemeManager.shared.currentMode == .classicLight) { [weak self] in self?.delegate?.menuDidSelectTheme(.classicLight) },
            .item("Tema: Windows 11 (Oscuro)", isChecked: ThemeManager.shared.currentMode == .dark) { [weak self] in self?.delegate?.menuDidSelectTheme(.dark) },
            .item("Tema: Automático (Sistema)", isChecked: ThemeManager.shared.currentMode == .system) { [weak self] in self?.delegate?.menuDidSelectTheme(.system) }
        ]
    }
    
    private func buildHelpItems() -> [MenuItemModel] {
        return [
            .item("Ver la Ayuda") { [weak self] in self?.delegate?.menuDidSelectHelp() },
            .item("Buscar actualizaciones...") { [weak self] in self?.delegate?.menuDidCheckUpdates() },
            .separator(),
            .item("Acerca del Bloc de notas") { [weak self] in self?.delegate?.menuDidSelectAbout() }
        ]
    }
}
