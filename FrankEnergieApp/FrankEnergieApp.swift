// ABOUTME: Main entry point for the Frank Energie Widget host application.
// ABOUTME: Required by macOS to host the widget extension. Provides a minimal settings UI.

import SwiftUI

@main
struct FrankEnergieApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
