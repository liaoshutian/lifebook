import SwiftUI

extension Color {
    static let accentBlue = Color(red: 0.10, green: 0.45, blue: 0.95)

    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xff) / 255,
            green: Double((value >> 8) & 0xff) / 255,
            blue: Double(value & 0xff) / 255
        )
    }
}

extension View {
    func cardStyle() -> some View {
        padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.quaternary, lineWidth: 1)
            }
    }
}

