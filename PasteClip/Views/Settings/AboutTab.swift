import SwiftUI

struct AboutTab: View {
    @EnvironmentObject private var updaterViewModel: CheckForUpdatesViewModel

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "clipboard")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("PasteClip")
                .font(.title.bold())

            Text("Version \(appVersion) (\(buildNumber))")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text("A simple clipboard manager for macOS.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Button("Check for Updates...") {
                updaterViewModel.checkForUpdates()
            }
            .disabled(!updaterViewModel.canCheckForUpdates)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
