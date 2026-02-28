import SwiftUI
import SwiftData

struct ExclusionSettingsTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExcludedApp.appName) private var excludedApps: [ExcludedApp]
    @Environment(AppState.self) private var appState
    @State private var selection: ExcludedApp?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Excluded apps will not have their clipboard content saved.")
                .font(.callout)
                .foregroundStyle(.secondary)

            List(excludedApps, selection: $selection) { app in
                HStack {
                    Image(nsImage: AppIconProvider.icon(for: app.bundleId, size: 24))
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text(app.appName)
                    Spacer()
                    Text(app.bundleId)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .tag(app)
            }
            .listStyle(.bordered)
            .frame(minHeight: 160)

            HStack {
                Button {
                    addApp()
                } label: {
                    Image(systemName: "plus")
                }

                Button {
                    removeSelected()
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selection == nil)

                Spacer()
            }
        }
        .padding()
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.title = "Select App to Exclude"
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let bundle = Bundle(url: url),
              let bundleId = bundle.bundleIdentifier else { return }

        let appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent

        // Check duplicate
        if excludedApps.contains(where: { $0.bundleId == bundleId }) { return }

        let excluded = ExcludedApp(bundleId: bundleId, appName: appName)
        modelContext.insert(excluded)
        try? modelContext.save()
        appState.clipboardMonitor.loadExcludedApps()
    }

    private func removeSelected() {
        guard let app = selection else { return }
        modelContext.delete(app)
        try? modelContext.save()
        selection = nil
        appState.clipboardMonitor.loadExcludedApps()
    }
}
