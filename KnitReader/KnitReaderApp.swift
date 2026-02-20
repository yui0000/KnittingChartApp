import SwiftUI
import SwiftData

@main
struct KnitReaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DocumentProgress.self)
    }
}
