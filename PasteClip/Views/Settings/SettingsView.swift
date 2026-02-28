import SwiftUI
import SwiftData

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AppearanceSettingsTab()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            ShortcutSettingsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            ExclusionSettingsTab()
                .tabItem {
                    Label("Exclusions", systemImage: "nosign")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 360)
    }
}
