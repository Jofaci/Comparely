import SwiftUI
import SwiftData

@main
struct CompareItApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Comparison.self,
            ComparedItem.self,
            ProConEntry.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ComparisonListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
