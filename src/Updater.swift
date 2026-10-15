import AppKit

class AppUpdater {
    static let shared = AppUpdater()
    
    let currentVersion = "1.2.0"
    let githubRepo = "hernycai/bloc-de-notas-macos"
    
    var repoURL: URL {
        return URL(string: "https://github.com/\(githubRepo)")!
    }
    
    func checkForUpdates(in window: NSWindow?, userInitiated: Bool = true) {
        let apiURL = URL(string: "https://api.github.com/repos/\(githubRepo)/releases/latest")!
        var request = URLRequest(url: apiURL)
        request.setValue("BlocDeNotas-macOS/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    if userInitiated {
                        self.showFallbackDialog(in: window)
                    }
                    return
                }
                
                let latestTag = (json["tag_name"] as? String)?.replacingOccurrences(of: "v", with: "") ?? ""
                let releaseName = json["name"] as? String ?? "Versión \(latestTag)"
                let releaseBody = json["body"] as? String ?? "Mejoras de rendimiento y correcciones de errores."
                let htmlURL = (json["html_url"] as? String).flatMap { URL(string: $0) } ?? self.repoURL
                
                var dmgDownloadURL: URL?
                if let assets = json["assets"] as? [[String: Any]] {
                    for asset in assets {
                        if let name = asset["name"] as? String, name.hasSuffix(".dmg"),
                           let dlStr = asset["browser_download_url"] as? String,
                           let dlURL = URL(string: dlStr) {
                            dmgDownloadURL = dlURL
                            break
                        }
                    }
                }
                
                if self.isVersion(latestTag, newerThan: self.currentVersion) {
                    self.showUpdateAvailableDialog(latestVersion: latestTag, name: releaseName, notes: releaseBody, downloadURL: dmgDownloadURL ?? htmlURL, releaseURL: htmlURL, in: window)
                } else {
                    if userInitiated {
                        self.showUpToDateDialog(in: window)
                    }
                }
            }
        }.resume()
    }
    
    private func isVersion(_ v1: String, newerThan v2: String) -> Bool {
        return v1.compare(v2, options: .numeric) == .orderedDescending
    }
    
    private func showUpdateAvailableDialog(latestVersion: String, name: String, notes: String, downloadURL: URL, releaseURL: URL, in window: NSWindow?) {
        let alert = NSAlert()
        alert.messageText = "¡Nueva actualización disponible!"
        alert.informativeText = """
        Se encuentra disponible la versión \(latestVersion) de Bloc de notas.
        
        Notas de la versión:
        \(notes.prefix(300))
        
        ¿Deseas descargar la actualización ahora?
        """
        alert.addButton(withTitle: "Descargar DMG")
        alert.addButton(withTitle: "Ver en GitHub")
        alert.addButton(withTitle: "Más tarde")
        
        if let win = window {
            alert.beginSheetModal(for: win) { response in
                if response == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(downloadURL)
                } else if response == .alertSecondButtonReturn {
                    NSWorkspace.shared.open(releaseURL)
                }
            }
        } else {
            let res = alert.runModal()
            if res == .alertFirstButtonReturn {
                NSWorkspace.shared.open(downloadURL)
            } else if res == .alertSecondButtonReturn {
                NSWorkspace.shared.open(releaseURL)
            }
        }
    }
    
    private func showUpToDateDialog(in window: NSWindow?) {
        let alert = NSAlert()
        alert.messageText = "Estás al día"
        alert.informativeText = "Tienes instalada la versión más reciente de Bloc de notas (v\(currentVersion))."
        alert.addButton(withTitle: "Aceptar")
        alert.addButton(withTitle: "Visitar GitHub")
        
        if let win = window {
            alert.beginSheetModal(for: win) { response in
                if response == .alertSecondButtonReturn {
                    NSWorkspace.shared.open(self.repoURL)
                }
            }
        } else {
            let res = alert.runModal()
            if res == .alertSecondButtonReturn {
                NSWorkspace.shared.open(self.repoURL)
            }
        }
    }
    
    private func showFallbackDialog(in window: NSWindow?) {
        let alert = NSAlert()
        alert.messageText = "Bloc de notas para macOS"
        alert.informativeText = """
        Versión instalada: v\(currentVersion)
        Repositorio oficial: https://github.com/\(githubRepo)
        
        No se pudieron obtener datos del servidor en este momento. Puedes verificar el repositorio de GitHub manualmente.
        """
        alert.addButton(withTitle: "Aceptar")
        alert.addButton(withTitle: "Abrir repositorio en GitHub")
        
        if let win = window {
            alert.beginSheetModal(for: win) { response in
                if response == .alertSecondButtonReturn {
                    NSWorkspace.shared.open(self.repoURL)
                }
            }
        } else {
            let res = alert.runModal()
            if res == .alertSecondButtonReturn {
                NSWorkspace.shared.open(self.repoURL)
            }
        }
    }
}
