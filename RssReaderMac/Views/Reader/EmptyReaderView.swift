import SwiftUI

/// Placeholder view shown when no article is selected in the reader pane.
struct EmptyReaderView: View {
    var body: some View {
        Text("Select an article")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyReaderView()
        .frame(width: 600, height: 400)
}
