import SwiftUI
import SwiftData
import AppKit

struct WelcomeView: View {
    @Binding var showWelcome: Bool
    @Environment(\.modelContext) private var modelContext

    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let buttonWidth: CGFloat = 280

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Icon
            Image(systemName: "dot.radiowaves.up.forward")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            // Title and Subtitle
            VStack(spacing: 12) {
                Text("Welcome to RssReaderMac")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("A clean, distraction-free RSS reader for your Mac")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                Button(action: importMyFeeds) {
                    Text("Import My Feeds")
                        .frame(width: buttonWidth)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: startWithPopularBlogs) {
                    Text("Start with Popular Blogs")
                        .frame(width: buttonWidth)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(action: startEmpty) {
                    Text("Start Empty")
                        .frame(width: buttonWidth)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Spacer()
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding(48)
        .alert("Import Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    // MARK: - Actions

    private func importMyFeeds() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.xml, .init(filenameExtension: "opml")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select an OPML file to import your feeds"
        panel.prompt = "Import"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            do {
                let parser = OPMLParser()
                let document = try parser.parse(url: url)
                importFeeds(from: document.feeds)
                finishOnboarding()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func startWithPopularBlogs() {
        guard let sampleURL = Bundle.main.url(forResource: "SampleFeeds", withExtension: "opml") else {
            errorMessage = "Could not find sample feeds file"
            showError = true
            return
        }

        do {
            let parser = OPMLParser()
            let document = try parser.parse(url: sampleURL)
            importFeeds(from: document.feeds)
            finishOnboarding()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func startEmpty() {
        finishOnboarding()
    }

    // MARK: - Helpers

    private func importFeeds(from opmlFeeds: [OPMLFeed]) {
        for opmlFeed in opmlFeeds {
            let feed = Feed(
                title: opmlFeed.title,
                feedURL: opmlFeed.feedURL,
                siteURL: opmlFeed.siteURL,
                folder: opmlFeed.folder
            )
            modelContext.insert(feed)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save feeds: \(error)")
        }
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        showWelcome = false
    }
}

#Preview {
    WelcomeView(showWelcome: .constant(true))
        .modelContainer(for: Feed.self, inMemory: true)
}
