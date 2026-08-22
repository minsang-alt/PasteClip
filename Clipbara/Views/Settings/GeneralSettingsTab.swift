import SwiftUI
import SwiftData
import ServiceManagement
import UniformTypeIdentifiers

struct GeneralSettingsTab: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage("historyLimit") private var historyLimit: Int = 500
    @AppStorage(PasteService.alwaysPlainTextDefaultsKey) private var alwaysPastePlainText: Bool = false
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @State private var transferMessage: String?
    @State private var showTransferAlert = false

    var body: some View {
        Form {
            Picker("History Limit", selection: $historyLimit) {
                Text("100").tag(100)
                Text("500").tag(500)
                Text("1,000").tag(1000)
                Text("5,000").tag(5000)
                Text("Unlimited").tag(0)
            }
            .pickerStyle(.menu)

            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = !newValue
                    }
                }

            Section("Pasting") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text("Always Paste as Plain Text")
                            InfoHoverButton(text: "Removes fonts, colors, and links from rich text and HTML clips, pasting only the text.")
                        }
                        Text("Hold \u{21e7} while pasting to switch for a single paste.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $alwaysPastePlainText)
                        .labelsHidden()
                }
            }

            Section("Backup") {
                LabeledContent("Export history, pinboards, and settings to a JSON file.") {
                    Button("Export\u{2026}") { exportHistory() }
                }
                LabeledContent("Import a backup file. Existing clips are kept; duplicates are skipped.") {
                    Button("Import\u{2026}") { importHistory() }
                }
            }

            Section {
                LabeledContent("Replay the first-run welcome tour.") {
                    Button("Show Welcome Tour\u{2026}") { showWelcomeTour() }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("Backup", isPresented: $showTransferAlert, presenting: transferMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private func showWelcomeTour() {
        guard let container = appState.modelContainer else { return }
        OnboardingWindowController.shared.show(appState: appState, modelContainer: container)
    }

    private func exportHistory() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "clipbara-backup.json"
        panel.title = "Export Clipbara Backup"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try TransferService.exportDocument(context: modelContext)
            try data.write(to: url)
            transferMessage = "Backup exported successfully."
        } catch {
            transferMessage = "Export failed: \(error.localizedDescription)"
        }
        showTransferAlert = true
    }

    private func importHistory() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Import Clipbara Backup"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            let summary = try TransferService.importDocument(data, context: modelContext)
            transferMessage = "Imported \(summary.importedItems) clips"
                + (summary.skippedItems > 0 ? " (\(summary.skippedItems) duplicates skipped)" : "")
                + (summary.importedBoards > 0 ? ", \(summary.importedBoards) pinboards" : "")
                + "."
        } catch {
            transferMessage = "Import failed: \(error.localizedDescription)"
        }
        showTransferAlert = true
    }
}
