import AppKit

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    
    private let themePopup = NSPopUpButton()
    private let fontPopup = NSPopUpButton()
    private let sizePopup = NSPopUpButton()
    private let wordWrapCheck = NSButton()
    private let lineEndingPopup = NSPopUpButton()
    private let encodingPopup = NSPopUpButton()
    private let formatBarCheck = NSButton()
    private let statusBarCheck = NSButton()
    
    init() {
        let contentRect = NSRect(x: 200, y: 200, width: 520, height: 500)
        let styleMask: NSWindow.StyleMask = [.titled, .closable]
        let window = NSWindow(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)
        super.init(window: window)
        window.title = "Configuración - Bloc de notas"
        window.center()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI() {
        guard let window = self.window else { return }
        
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 500))
        contentView.wantsLayer = true
        window.contentView = contentView
        
        var y: CGFloat = 455
        
        // Header
        let headerLabel = NSTextField(labelWithString: "⚙️ Configuración del Bloc de notas")
        headerLabel.font = NSFont.boldSystemFont(ofSize: 16)
        headerLabel.frame = NSRect(x: 24, y: y, width: 450, height: 24)
        contentView.addSubview(headerLabel)
        
        y -= 35
        
        // SECTION 1: Apariencia
        let sec1 = createSectionLabel(title: "APARIENCIA Y TEMA", y: y)
        contentView.addSubview(sec1)
        y -= 28
        
        let themeLabel = createRowLabel(title: "Tema de la aplicación:", y: y)
        contentView.addSubview(themeLabel)
        themePopup.frame = NSRect(x: 210, y: y - 2, width: 280, height: 24)
        themePopup.addItems(withTitles: [
            "Usar configuración del sistema (Por omisión)",
            "Modo claro (Windows Clásico)",
            "Modo oscuro (Windows 11)"
        ])
        themePopup.target = self
        themePopup.action = #selector(onThemeChanged)
        contentView.addSubview(themePopup)
        
        y -= 38
        
        // SECTION 2: Tipografía
        let sec2 = createSectionLabel(title: "TIPOGRAFÍA POR DEFECTO", y: y)
        contentView.addSubview(sec2)
        y -= 28
        
        let fontLabel = createRowLabel(title: "Familia de fuente:", y: y)
        contentView.addSubview(fontLabel)
        fontPopup.frame = NSRect(x: 210, y: y - 2, width: 280, height: 24)
        let fonts = ["Consolas", "Menlo", "Courier New", "SF Pro", "Monaco", "Helvetica", "Arial", "Georgia"]
        fontPopup.addItems(withTitles: fonts)
        fontPopup.target = self
        fontPopup.action = #selector(onFontChanged)
        contentView.addSubview(fontPopup)
        
        y -= 30
        let sizeLabel = createRowLabel(title: "Tamaño de fuente:", y: y)
        contentView.addSubview(sizeLabel)
        sizePopup.frame = NSRect(x: 210, y: y - 2, width: 100, height: 24)
        let sizes = ["9", "10", "11", "12", "14", "16", "18", "20", "24", "28", "32"]
        sizePopup.addItems(withTitles: sizes)
        sizePopup.target = self
        sizePopup.action = #selector(onSizeChanged)
        contentView.addSubview(sizePopup)
        
        y -= 38
        
        // SECTION 3: Comportamiento del Editor
        let sec3 = createSectionLabel(title: "COMPORTAMIENTO DEL EDITOR", y: y)
        contentView.addSubview(sec3)
        y -= 26
        
        wordWrapCheck.setButtonType(.switch)
        wordWrapCheck.title = "Ajuste de línea automático (Word wrap) por omisión"
        wordWrapCheck.font = ThemeManager.shared.uiFont(size: 12)
        wordWrapCheck.frame = NSRect(x: 24, y: y, width: 450, height: 20)
        wordWrapCheck.target = self
        wordWrapCheck.action = #selector(onWordWrapChanged)
        contentView.addSubview(wordWrapCheck)
        
        y -= 28
        let leLabel = createRowLabel(title: "Saltos de línea por omisión:", y: y)
        contentView.addSubview(leLabel)
        lineEndingPopup.frame = NSRect(x: 210, y: y - 2, width: 200, height: 24)
        lineEndingPopup.addItems(withTitles: ["Windows (CRLF)", "Unix (LF)"])
        lineEndingPopup.target = self
        lineEndingPopup.action = #selector(onLineEndingChanged)
        contentView.addSubview(lineEndingPopup)
        
        y -= 28
        let encLabel = createRowLabel(title: "Codificación por omisión:", y: y)
        contentView.addSubview(encLabel)
        encodingPopup.frame = NSRect(x: 210, y: y - 2, width: 200, height: 24)
        encodingPopup.addItems(withTitles: ["UTF-8", "ANSI (Windows-1252)"])
        encodingPopup.target = self
        encodingPopup.action = #selector(onEncodingChanged)
        contentView.addSubview(encodingPopup)
        
        y -= 26
        formatBarCheck.setButtonType(.switch)
        formatBarCheck.title = "Mostrar barra de herramientas de formato al abrir"
        formatBarCheck.font = ThemeManager.shared.uiFont(size: 12)
        formatBarCheck.frame = NSRect(x: 24, y: y, width: 450, height: 20)
        formatBarCheck.target = self
        formatBarCheck.action = #selector(onFormatBarChanged)
        contentView.addSubview(formatBarCheck)
        
        y -= 24
        statusBarCheck.setButtonType(.switch)
        statusBarCheck.title = "Mostrar barra de estado al abrir"
        statusBarCheck.font = ThemeManager.shared.uiFont(size: 12)
        statusBarCheck.frame = NSRect(x: 24, y: y, width: 450, height: 20)
        statusBarCheck.target = self
        statusBarCheck.action = #selector(onStatusBarChanged)
        contentView.addSubview(statusBarCheck)
        
        y -= 38
        
        // SECTION 4: Actualizaciones y Repositorio
        let sec4 = createSectionLabel(title: "ACTUALIZACIONES Y REPOSITORIO GITHUB", y: y)
        contentView.addSubview(sec4)
        y -= 30
        
        let versionLabel = NSTextField(labelWithString: "Versión instalada: v\(AppUpdater.shared.currentVersion)")
        versionLabel.font = ThemeManager.shared.uiFont(size: 12)
        versionLabel.frame = NSRect(x: 24, y: y, width: 180, height: 20)
        contentView.addSubview(versionLabel)
        
        let checkUpdateBtn = NSButton(frame: NSRect(x: 210, y: y - 2, width: 165, height: 24))
        checkUpdateBtn.title = "Buscar actualizaciones..."
        checkUpdateBtn.bezelStyle = .rounded
        checkUpdateBtn.font = ThemeManager.shared.uiFont(size: 11)
        checkUpdateBtn.target = self
        checkUpdateBtn.action = #selector(onCheckUpdates)
        contentView.addSubview(checkUpdateBtn)
        
        let gitHubBtn = NSButton(frame: NSRect(x: 382, y: y - 2, width: 110, height: 24))
        gitHubBtn.title = "Ver en GitHub"
        gitHubBtn.bezelStyle = .rounded
        gitHubBtn.font = ThemeManager.shared.uiFont(size: 11)
        gitHubBtn.target = self
        gitHubBtn.action = #selector(onOpenGitHub)
        contentView.addSubview(gitHubBtn)
        
        // Bottom close button
        let closeBtn = NSButton(frame: NSRect(x: 412, y: 14, width: 85, height: 26))
        closeBtn.title = "Aceptar"
        closeBtn.bezelStyle = .rounded
        closeBtn.target = self
        closeBtn.action = #selector(onClose)
        contentView.addSubview(closeBtn)
        
        loadCurrentConfig()
    }
    
    private func createSectionLabel(title: String, y: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.boldSystemFont(ofSize: 11)
        label.textColor = NSColor.secondaryLabelColor
        label.frame = NSRect(x: 24, y: y, width: 450, height: 18)
        return label
    }
    
    private func createRowLabel(title: String, y: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = ThemeManager.shared.uiFont(size: 12)
        label.frame = NSRect(x: 24, y: y, width: 180, height: 20)
        return label
    }
    
    func loadCurrentConfig() {
        let config = EditorConfig.shared
        
        switch config.themeMode {
        case .system:
            themePopup.selectItem(at: 0)
        case .classicLight:
            themePopup.selectItem(at: 1)
        case .dark:
            themePopup.selectItem(at: 2)
        }
        
        fontPopup.selectItem(withTitle: config.defaultFontFamily)
        sizePopup.selectItem(withTitle: "\(Int(config.defaultFontSize))")
        
        wordWrapCheck.state = config.defaultWordWrap ? .on : .off
        lineEndingPopup.selectItem(at: config.defaultLineEnding == .lf ? 1 : 0)
        encodingPopup.selectItem(at: config.defaultEncoding == .windowsCP1252 ? 1 : 0)
        
        formatBarCheck.state = config.showFormatBarByDefault ? .on : .off
        statusBarCheck.state = config.showStatusBarByDefault ? .on : .off
    }
    
    @objc private func onThemeChanged() {
        switch themePopup.indexOfSelectedItem {
        case 0:
            EditorConfig.shared.themeMode = .system
        case 1:
            EditorConfig.shared.themeMode = .classicLight
        case 2:
            EditorConfig.shared.themeMode = .dark
        default:
            break
        }
    }
    
    @objc private func onFontChanged() {
        if let f = fontPopup.selectedItem?.title {
            EditorConfig.shared.defaultFontFamily = f
        }
    }
    
    @objc private func onSizeChanged() {
        if let s = sizePopup.selectedItem?.title, let val = Double(s) {
            EditorConfig.shared.defaultFontSize = CGFloat(val)
        }
    }
    
    @objc private func onWordWrapChanged() {
        EditorConfig.shared.defaultWordWrap = (wordWrapCheck.state == .on)
    }
    
    @objc private func onLineEndingChanged() {
        EditorConfig.shared.defaultLineEnding = (lineEndingPopup.indexOfSelectedItem == 1) ? .lf : .crlf
    }
    
    @objc private func onEncodingChanged() {
        EditorConfig.shared.defaultEncoding = (encodingPopup.indexOfSelectedItem == 1) ? .windowsCP1252 : .utf8
    }
    
    @objc private func onFormatBarChanged() {
        EditorConfig.shared.showFormatBarByDefault = (formatBarCheck.state == .on)
    }
    
    @objc private func onStatusBarChanged() {
        EditorConfig.shared.showStatusBarByDefault = (statusBarCheck.state == .on)
    }
    
    @objc private func onCheckUpdates() {
        AppUpdater.shared.checkForUpdates(in: self.window, userInitiated: true)
    }
    
    @objc private func onOpenGitHub() {
        NSWorkspace.shared.open(AppUpdater.shared.repoURL)
    }
    
    @objc private func onClose() {
        window?.close()
    }
    
    func showSettings() {
        loadCurrentConfig()
        window?.center()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
