import SwiftUI

@main
struct MyApp: App {
    init() {
        NotificationService.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
