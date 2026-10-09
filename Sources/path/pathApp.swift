import SwiftUI

@main
struct PathApp: App {
    @State private var state = AppState.shared

    init() { _ = AppState.shared } // Überwachung startet sofort, nicht erst beim ersten Klick

    /// Gleiches Symbol wie das App-Icon, als Template-Bild (passt sich Hell/Dunkel an).
    private static let menuBarImage: NSImage? = {
        guard let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }()

    var body: some Scene {
        MenuBarExtra {
            ContentView(state: state)
        } label: {
            if let image = Self.menuBarImage {
                Image(nsImage: image)
            } else {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
