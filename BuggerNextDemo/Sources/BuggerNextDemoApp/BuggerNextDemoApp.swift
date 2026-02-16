import SwiftUI
import Bugger

@main
struct BuggerNextDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                BuggerScreen()
                    .navigationTitle("Bug Reporter")
            }
        }
    }
}
