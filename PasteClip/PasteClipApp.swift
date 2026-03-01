import SwiftUI
import SwiftData
import Sparkle

@main
struct PasteClipApp: App {
    @State private var appState = AppState()
    @StateObject private var updaterViewModel = CheckForUpdatesViewModel()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClipboardItem.self,
            Pinboard.self,
            PinboardEntry.self,
            ExcludedApp.self,
        ])

        // Back up existing store before SwiftData opens it (prevents silent data loss on schema mismatch)
        let fm = FileManager.default
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let storeURL = appSupport.appendingPathComponent("default.store")
            if fm.fileExists(atPath: storeURL.path) {
                let backupURL = appSupport.appendingPathComponent("default.store.backup")
                try? fm.removeItem(at: backupURL)
                try? fm.copyItem(at: storeURL, to: backupURL)
            }
        }

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
                .environmentObject(updaterViewModel)
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
                .environmentObject(updaterViewModel)
                .modelContainer(sharedModelContainer)
        }
    }

    init() {
        let context = sharedModelContainer.mainContext
        appState.start(modelContext: context, modelContainer: sharedModelContainer)

        // Apply saved theme on launch (NSApp is not ready in init, defer it)
        DispatchQueue.main.async { [sharedModelContainer] in
            let theme = UserDefaults.standard.string(forKey: "appTheme") ?? "System"
            switch theme {
            case "Light": NSApp.appearance = NSAppearance(named: .aqua)
            case "Dark": NSApp.appearance = NSAppearance(named: .darkAqua)
            default: NSApp.appearance = nil
            }

            // Save SwiftData on app termination
            NotificationCenter.default.addObserver(
                forName: NSApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { _ in
                try? sharedModelContainer.mainContext.save()
            }
        }
    }
}
