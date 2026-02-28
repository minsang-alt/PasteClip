import Foundation
import SwiftData

@Model
final class ExcludedApp {
    #Unique<ExcludedApp>([\.bundleId])

    var bundleId: String
    var appName: String

    init(bundleId: String, appName: String) {
        self.bundleId = bundleId
        self.appName = appName
    }
}
