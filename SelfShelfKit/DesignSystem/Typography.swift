import SwiftUI

public enum AppFont {
    public static let serifName = "Sentient-Light"
    public static let sansLight = "ArchivoRoman-Light"
    public static let sansRegular = "ArchivoRoman-Regular"
    public static let sansMedium = "ArchivoRoman-Medium"
    public static let monoName = "PTMono-Regular"
}

public extension Font {
    static func serif(_ size: CGFloat) -> Font {
        .custom(AppFont.serifName, size: size)
    }
    static func sans(_ size: CGFloat, weight: SansWeight = .regular) -> Font {
        .custom(weight.psName, size: size)
    }
    static func mono(_ size: CGFloat) -> Font {
        .custom(AppFont.monoName, size: size)
    }
}

public enum SansWeight {
    case light, regular, medium
    var psName: String {
        switch self {
        case .light: return AppFont.sansLight
        case .regular: return AppFont.sansRegular
        case .medium: return AppFont.sansMedium
        }
    }
}

public struct MonoCaption: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .font(.mono(11))
            .textCase(.uppercase)
            .tracking(1.2)
            .opacity(0.7)
    }
}

public extension View {
    func monoCaption() -> some View { modifier(MonoCaption()) }
}
