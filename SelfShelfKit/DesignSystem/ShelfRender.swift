import SwiftUI

// MARK: - ShelfBackground
//
// Rebuilt from Figma (file GSyG9MEBSBhTvZFWKqJNNw, node 1:6).
// The design is a rounded "wall" with a soft inner ellipse shadow sitting
// above a thin shelf plank. Everything is drawn with SwiftUI shape
// primitives so the colors are fully customizable (no raster assets).
public struct ShelfBackground: View {
    public let hex: String
    public let preset: StylePreset

    public init(hex: String, preset: StylePreset) {
        self.hex = hex
        self.preset = preset
    }

    public var body: some View {
        let base = Color(hex: hex)
        let ink = base.contrastingInk()

        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Wall fill — the frame background from Figma.
                wallFill(base: base)

                // "Background shadow" ellipse from Figma: a soft, wide oval
                // that sits in the lower portion of the wall and fades the
                // surface toward the shelf plank.
                Ellipse()
                    .fill(ink.opacity(0.10))
                    .frame(width: w * 0.94, height: h * 0.58)
                    .blur(radius: 18)
                    .offset(y: h * 0.30)
                    .blendMode(.multiply)
                    .allowsHitTesting(false)

                // Subtle top highlight so the wall reads as lit from above.
                LinearGradient(
                    colors: [Color.white.opacity(0.18), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .allowsHitTesting(false)

                if preset == .bordered {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(ink.opacity(0.35), lineWidth: 1.5)
                        .padding(6)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    @ViewBuilder
    private func wallFill(base: Color) -> some View {
        switch preset {
        case .flat, .bordered:
            base
        case .gradient:
            LinearGradient(
                colors: [base.lightened(by: 0.04), base, base.darkened(by: 0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - ShelfPlank
//
// The Figma "Shelf" node: a thin rounded rectangle with a warm drop
// shadow (0px 3px 4px rgba(110,81,32,0.1), 0px 3px 12px rgba(0,0,0,0.15)).
// Fill is a slightly lightened variant of the wall color so the plank
// reads as a lit surface regardless of the customized tone.
public struct ShelfPlank: View {
    public let hex: String
    public init(hex: String) { self.hex = hex }

    public var body: some View {
        let base = Color(hex: hex)
        let plank = base.lightened(by: 0.08)

        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        plank.lightened(by: 0.05),
                        plank,
                        plank.darkened(by: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 8)
            .shadow(color: Color(red: 110/255, green: 81/255, blue: 32/255).opacity(0.10), radius: 2, x: 0, y: 3)
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
    }
}

// MARK: - Color helpers
private extension Color {
    func lightened(by amount: CGFloat) -> Color {
        adjust(brightness: amount)
    }
    func darkened(by amount: CGFloat) -> Color {
        adjust(brightness: -amount)
    }
    private func adjust(brightness delta: CGFloat) -> Color {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            let nb = max(0, min(1, b + delta))
            return Color(UIColor(hue: h, saturation: s, brightness: nb, alpha: a))
        }
        #endif
        return self
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
