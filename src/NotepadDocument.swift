import Foundation

enum LineEnding: String {
    case crlf = "Windows (CRLF)"
    case lf = "Unix (LF)"
    case cr = "Macintosh (CR)"
    
    var stringValue: String {
        switch self {
        case .crlf: return "\r\n"
        case .lf: return "\n"
        case .cr: return "\r"
        }
    }
}

class NotepadDocument {
    var fileURL: URL?
    var isDirty: Bool = false
    var encoding: String.Encoding = .utf8
    var lineEnding: LineEnding = .crlf
    
    var displayName: String {
        return fileURL?.lastPathComponent ?? "Sin título"
    }
    
    var windowTitle: String {
        let prefix = isDirty ? "*" : ""
        return "\(prefix)\(displayName) - Bloc de notas"
    }
    
    var encodingName: String {
        switch encoding {
        case .utf8:
            return "UTF-8"
        case .utf16BigEndian:
            return "UTF-16 BE"
        case .utf16LittleEndian:
            return "UTF-16 LE"
        case .windowsCP1252:
            return "ANSI (Windows-1252)"
        case .isoLatin1:
            return "ISO-8859-1"
        default:
            return "UTF-8"
        }
    }
    
    func detectLineEnding(in text: String) -> LineEnding {
        if text.contains("\r\n") {
            return .crlf
        } else if text.contains("\n") {
            return .lf
        } else if text.contains("\r") {
            return .cr
        }
        return .crlf // Classic Windows default
    }
}
