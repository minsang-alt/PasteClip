import SwiftUI
import AppKit

struct ColorCardContent: View {
    let item: ClipboardItem

    private var hexString: String {
        item.textContent ?? "#000000"
    }

    private var color: Color {
        Color(nsColor: NSColor.fromHex(hexString) ?? .black)
    }

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )

            Text(hexString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
