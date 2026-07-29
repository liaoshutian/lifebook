import SwiftData
import SwiftUI

@main
struct LifeBookApp: App {
    private let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(Color.accentBlue)
        }
        .modelContainer(
            for: [LifeEntry.self, EventDefinition.self],
            inMemory: isUITesting
        )
    }
}
