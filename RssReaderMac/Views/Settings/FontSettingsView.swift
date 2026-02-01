import SwiftUI

/// Font customization settings view with live preview.
struct FontSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Picker("Font Family", selection: $settings.selectedFontFamily) {
                    ForEach(AppSettings.FontFamily.allCases) { family in
                        Text(family.displayName)
                            .tag(family)
                    }
                }
                .pickerStyle(.segmented)

                LabeledContent("Font Size") {
                    HStack {
                        Slider(
                            value: $settings.fontSize,
                            in: 12...24,
                            step: 1
                        )
                        .frame(width: 150)

                        Text("\(Int(settings.fontSize)) pt")
                            .monospacedDigit()
                            .frame(width: 45, alignment: .trailing)
                    }
                }

                LabeledContent("Line Spacing") {
                    HStack {
                        Slider(
                            value: $settings.lineSpacing,
                            in: 2...12,
                            step: 1
                        )
                        .frame(width: 150)

                        Text("\(Int(settings.lineSpacing)) pt")
                            .monospacedDigit()
                            .frame(width: 45, alignment: .trailing)
                    }
                }
            } header: {
                Text("Text Settings")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(settings.titleFont)

                    Text(previewText)
                        .font(settings.bodyFont)
                        .lineSpacing(settings.lineSpacing)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Preview")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 350, minHeight: 280)
    }

    private var previewText: String {
        "The quick brown fox jumps over the lazy dog. This sample text demonstrates how your chosen font settings will appear in the reader view."
    }
}

#Preview {
    FontSettingsView()
        .environment(AppSettings())
        .frame(width: 400, height: 350)
}
