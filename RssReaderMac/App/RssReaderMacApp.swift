import SwiftUI
import SwiftData

@main
struct RssReaderMacApp: App {
    /// Key for tracking if onboarding has been completed
    private static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    /// The model container for SwiftData persistence
    private let modelContainer: ModelContainer

    /// App-wide settings for font customization
    @State private var settings = AppSettings()

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
            .environment(settings)
        }
        .commands {
            AppCommands()
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)

        // Reading View window for immersive reading
        WindowGroup("Reading View", for: UUID.self) { $articleId in
            ReadingViewWindow(articleId: articleId)
                .modelContainer(modelContainer)
                .environment(settings)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 900)

        // Settings window
        Settings {
            FontSettingsView()
                .environment(settings)
        }
    }
}
