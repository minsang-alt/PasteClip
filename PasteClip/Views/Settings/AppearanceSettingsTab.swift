import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

struct AppearanceSettingsTab: View {
    @AppStorage("appTheme") private var appTheme: String = AppTheme.system.rawValue

    var body: some View {
        Form {
            Picker("Theme", selection: $appTheme) {
                ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                    Text(theme.rawValue).tag(theme.rawValue)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: appTheme) { _, newValue in
                applyTheme(newValue)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            applyTheme(appTheme)
        }
    }

    private func applyTheme(_ theme: String) {
        switch AppTheme(rawValue: theme) {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }
}
