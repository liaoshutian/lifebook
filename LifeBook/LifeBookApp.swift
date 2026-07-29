import SwiftData
import SwiftUI

@main
struct LifeBookApp: App {
    private let isTesting =
        ProcessInfo.processInfo.arguments.contains("-ui-testing") ||
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(Color.accentBlue)
        }
        .modelContainer(
            for: [LifeEntry.self, EventDefinition.self],
            inMemory: isTesting
        )
    }
}
