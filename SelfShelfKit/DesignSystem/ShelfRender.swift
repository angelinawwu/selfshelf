import SwiftUI

public struct ShelfBackground: View {
    public let hex: String
    public let preset: StylePreset

    public init(hex: String, preset: StylePreset) {
        self.hex = hex
        self.preset = preset
    }

    public var body: some View {
        let base = Color(hex: hex)
        switch preset {
        case .flat:
            base
        case .gradient:
            LinearGradient(
                colors: [base, base.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .bordered:
            ZStack {
                base
                RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(base.contrastingInk().opacity(0.35), lineWidth: 1.5)
                    .padding(6)
            }
        }
    }
}

public struct ShelfPlank: View {
    public let hex: String
    public init(hex: String) { self.hex = hex }
    public var body: some View {
        Rectangle()
            .fill(Color(hex: hex).contrastingInk().opacity(0.25))
            .frame(height: 1.5)
    }
}

public struct BookCoverView: View {
    public let coverId: Int?
    public let title: String
    public let fallbackTint: Color
    public let cornerRadius: CGFloat

    public init(coverId: Int?, title: String, fallbackTint: Color = AppTheme.ink.opacity(0.9), cornerRadius: CGFloat = 2) {
        self.coverId = coverId
        self.title = title
        self.fallbackTint = fallbackTint
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        ZStack {
            if let coverId, let ui = CoverCache.shared.loadImage(coverId: coverId, size: .medium) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 2, x: 1, y: 2)
    }

    private var placeholder: some View {
        GeometryReader { geo in
            ZStack {
                fallbackTint
                Text(String(title.prefix(1)).uppercased())
                    .font(.custom(AppFont.serifName, size: geo.size.width * 0.55))
                    .foregroundStyle(fallbackTint.contrastingInk())
            }
        }
    }
}
