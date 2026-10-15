import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var windowControllers: [NotepadWindowController] = []
    private var fileToOpenOnLaunch: URL?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMainMenu()
        
        if let fileURL = fileToOpenOnLaunch {
            openDocument(at: fileURL)
            fileToOpenOnLaunch = nil
        } else if windowControllers.isEmpty {
            createNewWindow()
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @discardableResult
    func createNewWindow() -> NotepadWindowController {
        let wc = NotepadWindowController()
        windowControllers.append(wc)
        wc.window?.center()
        
        // Offset if other windows exist
        if windowControllers.count > 1 {
            let offset = CGFloat(windowControllers.count - 1) * 24.0
            if let frame = wc.window?.frame {
                wc.window?.setFrameOrigin(NSPoint(x: frame.origin.x + offset, y: frame.origin.y - offset))
            }
        }
        
        wc.showWindow(nil)
        return wc
    }
    
    func openDocument(at url: URL) {
        // If single empty unmodified window exists, use it
        if windowControllers.count == 1,
           let first = windowControllers.first,
           first.notepadDoc.fileURL == nil,
           !first.notepadDoc.isDirty {
            first.loadFile(url: url)
            first.window?.makeKeyAndOrderFront(nil)
            return
        }
        
        let wc = createNewWindow()
        wc.loadFile(url: url)
        wc.window?.makeKeyAndOrderFront(nil)
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        if NSApp.isRunning {
            openDocument(at: url)
        } else {
            fileToOpenOnLaunch = url
        }
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        for wc in windowControllers {
            if wc.notepadDoc.isDirty {
                wc.window?.makeKeyAndOrderFront(nil)
                wc.confirmUnsavedChanges { canProceed in
                    if canProceed {
                        sender.reply(toApplicationShouldTerminate: true)
                    } else {
                        sender.reply(toApplicationShouldTerminate: false)
                    }
                }
                return .terminateLater
            }
        }
        return .terminateNow
    }
    
    // MARK: - Native macOS Top Menu Bar
    
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let appName = "Bloc de notas"
        
        appMenu.addItem(withTitle: "Acerca del \(appName)", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(withTitle: "Configuración...", action: #selector(showSettings), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Ocultar \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "Ocultar otros", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [NSEvent.ModifierFlags.command, NSEvent.ModifierFlags.option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(withTitle: "Mostrar todo", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Salir de \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // Archivo Menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "Archivo")
        fileMenu.addItem(withTitle: "Nuevo", action: #selector(menuActionNew), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Nueva ventana", action: #selector(menuActionNewWindow), keyEquivalent: "N")
        fileMenu.addItem(withTitle: "Abrir...", action: #selector(menuActionOpen), keyEquivalent: "o")
        fileMenu.addItem(withTitle: "Guardar", action: #selector(menuActionSave), keyEquivalent: "s")
        fileMenu.addItem(withTitle: "Guardar como...", action: #selector(menuActionSaveAs), keyEquivalent: "S")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Imprimir...", action: #selector(menuActionPrint), keyEquivalent: "p")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Cerrar ventana", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
        
        // Edición Menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edición")
        editMenu.addItem(withTitle: "Deshacer", action: #selector(menuActionUndo), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Rehacer", action: #selector(menuActionRedo), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cortar", action: #selector(menuActionCut), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copiar", action: #selector(menuActionCopy), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Pegar", action: #selector(menuActionPaste), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Eliminar", action: #selector(menuActionDelete), keyEquivalent: "")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Buscar...", action: #selector(menuActionFind), keyEquivalent: "f")
        editMenu.addItem(withTitle: "Buscar siguiente", action: #selector(menuActionFindNext), keyEquivalent: "g")
        editMenu.addItem(withTitle: "Reemplazar...", action: #selector(menuActionReplace), keyEquivalent: "h")
        editMenu.addItem(withTitle: "Ir a...", action: #selector(menuActionGoToLine), keyEquivalent: "l")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Seleccionar todo", action: #selector(menuActionSelectAll), keyEquivalent: "a")
        editMenu.addItem(withTitle: "Hora y fecha", action: #selector(menuActionTimeDate), keyEquivalent: "")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        
        // Formato Menu
        let formatMenuItem = NSMenuItem()
        let formatMenu = NSMenu(title: "Formato")
        formatMenu.addItem(withTitle: "Negrita", action: #selector(menuActionBold), keyEquivalent: "b")
        formatMenu.addItem(withTitle: "Cursiva", action: #selector(menuActionItalic), keyEquivalent: "i")
        formatMenu.addItem(withTitle: "Subrayado", action: #selector(menuActionUnderline), keyEquivalent: "u")
        formatMenu.addItem(withTitle: "Tachado", action: #selector(menuActionStrike), keyEquivalent: "")
        formatMenu.addItem(NSMenuItem.separator())
        formatMenu.addItem(withTitle: "Ajuste de línea", action: #selector(menuActionWordWrap), keyEquivalent: "")
        formatMenu.addItem(withTitle: "Fuente...", action: #selector(menuActionFont), keyEquivalent: "t")
        formatMenuItem.submenu = formatMenu
        mainMenu.addItem(formatMenuItem)
        
        // Ver Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "Ver")
        let zoomMenu = NSMenu(title: "Zoom")
        zoomMenu.addItem(withTitle: "Acercar", action: #selector(menuActionZoomIn), keyEquivalent: "+")
        zoomMenu.addItem(withTitle: "Alejar", action: #selector(menuActionZoomOut), keyEquivalent: "-")
        zoomMenu.addItem(withTitle: "Restaurar zoom predeterminado", action: #selector(menuActionResetZoom), keyEquivalent: "0")
        let zoomItem = NSMenuItem(title: "Zoom", action: nil, keyEquivalent: "")
        zoomItem.submenu = zoomMenu
        viewMenu.addItem(zoomItem)
        viewMenu.addItem(withTitle: "Barra de estado", action: #selector(menuActionToggleStatusBar), keyEquivalent: "")
        viewMenu.addItem(withTitle: "Barra de formato", action: #selector(menuActionToggleFormatBar), keyEquivalent: "")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Alternar modo claro / oscuro", action: #selector(menuActionToggleTheme), keyEquivalent: "D")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)
        
        // Ventana Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Ventana")
        windowMenu.addItem(withTitle: "Minimizar", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
        // Ayuda Menu
        let helpMenuItem = NSMenuItem()
        let helpMenu = NSMenu(title: "Ayuda")
        helpMenu.addItem(withTitle: "Ayuda del Bloc de notas", action: #selector(menuActionHelp), keyEquivalent: "")
        helpMenu.addItem(withTitle: "Buscar actualizaciones...", action: #selector(menuActionCheckUpdates), keyEquivalent: "")
        helpMenu.addItem(NSMenuItem.separator())
        helpMenu.addItem(withTitle: "Acerca del Bloc de notas", action: #selector(showAbout), keyEquivalent: "")
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    private var activeController: NotepadWindowController? {
        guard let keyWindow = NSApp.keyWindow else { return windowControllers.first }
        return windowControllers.first { $0.window == keyWindow }
    }
    
    @objc func showAbout() {
        if let window = NSApp.keyWindow {
            AboutDialog.show(in: window)
        }
    }
    
    @objc func menuActionNew() { activeController?.menuDidSelectNew() }
    @objc func menuActionNewWindow() { _ = createNewWindow() }
    @objc func menuActionOpen() { activeController?.menuDidSelectOpen() }
    @objc func menuActionSave() { activeController?.menuDidSelectSave() }
    @objc func menuActionSaveAs() { activeController?.menuDidSelectSaveAs() }
    @objc func menuActionPrint() { activeController?.menuDidSelectPrint() }
    @objc func menuActionUndo() { activeController?.menuDidSelectUndo() }
    @objc func menuActionRedo() { activeController?.menuDidSelectRedo() }
    @objc func menuActionCut() { activeController?.menuDidSelectCut() }
    @objc func menuActionCopy() { activeController?.menuDidSelectCopy() }
    @objc func menuActionPaste() { activeController?.menuDidSelectPaste() }
    @objc func menuActionDelete() { activeController?.menuDidSelectDelete() }
    @objc func menuActionFind() { activeController?.menuDidSelectFind() }
    @objc func menuActionFindNext() { activeController?.menuDidSelectFindNext() }
    @objc func menuActionReplace() { activeController?.menuDidSelectReplace() }
    @objc func menuActionGoToLine() { activeController?.menuDidSelectGoToLine() }
    @objc func menuActionSelectAll() { activeController?.menuDidSelectSelectAll() }
    @objc func menuActionTimeDate() { activeController?.menuDidSelectTimeDate() }
    @objc func menuActionWordWrap() { activeController?.menuDidToggleWordWrap() }
    @objc func menuActionFont() { activeController?.menuDidSelectFont() }
    @objc func menuActionBold() { activeController?.formatDidToggleBold() }
    @objc func menuActionItalic() { activeController?.formatDidToggleItalic() }
    @objc func menuActionUnderline() { activeController?.formatDidToggleUnderline() }
    @objc func menuActionStrike() { activeController?.formatDidToggleStrikethrough() }
    @objc func menuActionZoomIn() { activeController?.menuDidZoomIn() }
    @objc func menuActionZoomOut() { activeController?.menuDidZoomOut() }
    @objc func menuActionResetZoom() { activeController?.menuDidResetZoom() }
    @objc func menuActionToggleStatusBar() { activeController?.menuDidToggleStatusBar() }
    @objc func menuActionToggleFormatBar() { activeController?.menuDidToggleFormatBar() }
    @objc func menuActionToggleTheme() { activeController?.formatDidToggleTheme() }
    @objc func menuActionHelp() { activeController?.menuDidSelectHelp() }
    @objc func showSettings() { SettingsWindowController.shared.showSettings() }
    @objc func menuActionCheckUpdates() { AppUpdater.shared.checkForUpdates(in: NSApp.keyWindow, userInitiated: true) }
}
