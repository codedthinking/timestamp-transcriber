import SwiftUI

@main
struct TimestampApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
        .defaultSize(width: 760, height: 560)
        .windowResizability(.contentMinSize)
    }
}
