import Foundation
import SwiftData

/// Sample data for SwiftUI previews only. Not used at runtime.
enum PreviewData {
    static var inMemoryContainer: ModelContainer {
        do {
            let container = try ModelContainer(
                for: Comparison.self, ComparedItem.self, ProConEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let sample = sampleComparison
            container.mainContext.insert(sample)
            for item in sample.items {
                container.mainContext.insert(item)
                for entry in item.entries {
                    container.mainContext.insert(entry)
                }
            }
            return container
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
    }

    static var sampleComparison: Comparison {
        let comparison = Comparison(title: "Bike vs E-bike")
        let bike = ComparedItem(name: "Bike", side: 0, comparison: comparison)
        let eBike = ComparedItem(name: "E-bike", side: 1, comparison: comparison)
        bike.entries = [
            ProConEntry(text: "No charging needed", isPro: true, sortOrder: 0, item: bike),
            ProConEntry(text: "Great exercise", isPro: true, sortOrder: 1, item: bike),
            ProConEntry(text: "Hard on steep hills", isPro: false, sortOrder: 2, item: bike)
        ]
        eBike.entries = [
            ProConEntry(text: "Easy on hills", isPro: true, sortOrder: 0, item: eBike),
            ProConEntry(text: "Heavier to carry", isPro: false, sortOrder: 1, item: eBike),
            ProConEntry(text: "Needs charging", isPro: false, sortOrder: 2, item: eBike)
        ]
        comparison.items = [bike, eBike]
        comparison.saveVerdict("E-bike for commuting, bike for weekend rides.")
        return comparison
    }
}
