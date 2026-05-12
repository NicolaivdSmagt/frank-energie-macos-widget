// ABOUTME: Main content view for the host app, showing setup instructions.
// ABOUTME: Provides a simple UI explaining how to add the widget to the desktop.

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            // App icon / header
            VStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "F5A623"))

                Text("Frank Energie Widget")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Divider()

            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                Text("Widget toevoegen aan je bureaublad:")
                    .font(.headline)

                instructionRow(number: 1, text: "Klik met de rechtermuisknop op je bureaublad")
                instructionRow(number: 2, text: "Kies 'Wijzig widgets...'")
                instructionRow(number: 3, text: "Zoek naar 'Frank Energie'")
                instructionRow(number: 4, text: "Sleep de widget naar je bureaublad")
            }

            Divider()

            // Status
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Widget is beschikbaar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("Je kunt deze app sluiten. De widget werkt onafhankelijk.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(width: 380, height: 420)
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color(hex: "F5A623")))

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    ContentView()
}
