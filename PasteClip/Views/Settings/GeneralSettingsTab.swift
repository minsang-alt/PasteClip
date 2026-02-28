import SwiftUI
import ServiceManagement

struct GeneralSettingsTab: View {
    @AppStorage("historyLimit") private var historyLimit: Int = 500
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

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
        }
        .formStyle(.grouped)
        .padding()
    }
}
