import SwiftUI

@main
struct VoicmanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Dock ikonu ve standart pencere gizlenir — sadece floating panel görünür
        Settings { EmptyView() }
    }
}
