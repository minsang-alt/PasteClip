import SwiftUI
import KeyboardShortcuts

struct ShortcutSettingsTab: View {
    var body: some View {
        Form {
            HStack {
                Text("Toggle History Panel")
                Spacer()
                KeyboardShortcuts.Recorder(for: .toggleHistoryPanel)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
