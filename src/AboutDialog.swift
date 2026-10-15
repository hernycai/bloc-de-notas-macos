import AppKit

class AboutDialog {
    static func show(in window: NSWindow) {
        let alert = NSAlert()
        alert.messageText = "Acerca del Bloc de notas"
        
        var icon: NSImage?
        if let appIcon = NSApp.applicationIconImage {
            icon = appIcon
        } else if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                  let loadedIcon = NSImage(contentsOf: iconURL) {
            icon = loadedIcon
        }
        alert.icon = icon
        
        let info = """
        Bloc de notas de Windows (macOS Edition)
        Versión 11.2402.12.0
        
        Un editor de texto simple y rápido con la estética, atajos y funcionamiento idénticos al Bloc de notas de Windows.
        
        Características:
        • Barra de menús integrada (Archivo, Edición, Formato, Ver, Ayuda)
        • Ajuste de línea y selector de fuentes
        • Búsqueda y Reemplazo avanzado
        • Barra de estado con seguimiento en tiempo real (Línea, Columna, Zoom, CRLF/LF, UTF-8)
        • Atajo F5 para inserción automática de hora y fecha
        • Compatibilidad nativa macOS y apertura directa desde Finder
        
        © Microsoft Corporation (Diseño original)
        Portado nativo para macOS con Swift y AppKit.
        """
        
        alert.informativeText = info
        alert.addButton(withTitle: "Aceptar")
        alert.beginSheetModal(for: window, completionHandler: nil)
    }
}
