import SwiftUI
import SwiftData

@main
struct PasteClipApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClipboardItem.self,
            Pinboard.self,
            PinboardEntry.self,
            ExcludedApp.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra("PasteClip", systemImage: "clipboard") {
            MenuBarContentView()
                .environment(appState)
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
                .modelContainer(sharedModelContainer)
        }
    }

    init() {
        let context = sharedModelContainer.mainContext
        appState.start(modelContext: context, modelContainer: sharedModelContainer)

        // Apply saved theme on launch (NSApp is not ready in init, defer it)
        DispatchQueue.main.async {
            let theme = UserDefaults.standard.string(forKey: "appTheme") ?? "System"
            switch theme {
            case "Light": NSApp.appearance = NSAppearance(named: .aqua)
            case "Dark": NSApp.appearance = NSAppearance(named: .darkAqua)
            default: NSApp.appearance = nil
            }
        }
    }
}
