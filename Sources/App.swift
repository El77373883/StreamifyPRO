import SwiftUI

@main
struct StreamifyApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.dark) // Forzamos modo oscuro como Spotify
        }
    }
}