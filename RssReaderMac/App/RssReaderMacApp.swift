import SwiftUI
import SwiftData

@main
struct RssReaderMacApp: App {
    /// Key for tracking if onboarding has been completed
    private static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    /// The model container for SwiftData persistence
    private let modelContainer: ModelContainer

    /// Whether to show the welcome view for first-time users
    @State private var showWelcome: Bool

    init() {
        // Check if onboarding has been completed
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.hasCompletedOnboardingKey)
        _showWelcome = State(initialValue: !hasCompletedOnboarding)

        // Create the model container
        do {
            modelContainer = try ModelContainerSetup.createContainer()
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showWelcome {
                    WelcomeView(showWelcome: $showWelcome)
                } else {
                    ContentView()
                }
            }
            .modelContainer(modelContainer)
        }
        .commands {
            AppCommands()
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
    }
}
