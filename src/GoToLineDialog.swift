import AppKit

class GoToLineDialog {
    static func show(in window: NSWindow, currentLine: Int, maxLine: Int, completion: @escaping (Int?) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Ir a la línea"
        alert.informativeText = "Número de línea (1 - \(maxLine)):"
        alert.addButton(withTitle: "Ir a")
        alert.addButton(withTitle: "Cancelar")
        
        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputField.stringValue = "\(currentLine)"
        alert.accessoryView = inputField
        
        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                if let line = Int(inputField.stringValue.trimmingCharacters(in: .whitespaces)), line >= 1 {
                    completion(line)
                    return
                }
            }
            completion(nil)
        }
    }
}
