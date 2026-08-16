import SwiftUI

enum AppColor {
    static let accent = Color(red: 0.13, green: 0.36, blue: 0.32)
    static let accentSoft = Color(red: 0.90, green: 0.95, blue: 0.93)
    static let warm = Color(red: 0.96, green: 0.83, blue: 0.65)
    static let positive = Color(red: 0.18, green: 0.55, blue: 0.38)
}

enum AppFont {
    static func regular(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("LINESeedJPApp_TTF-Regular", size: size, relativeTo: style)
    }

    static func bold(_ size: CGFloat, relativeTo style: Font.TextStyle = .headline) -> Font {
        .custom("LINESeedJPApp_TTF-Bold", size: size, relativeTo: style)
    }

    static func extraBold(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom("LINESeedJPApp_TTF-ExtraBold", size: size, relativeTo: style)
    }
}

struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func cardSurface() -> some View {
        modifier(CardSurface())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.bold(17, relativeTo: .body))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AppColor.accent.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.bold(16, relativeTo: .body))
            .foregroundStyle(AppColor.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(AppColor.accentSoft.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SectionHeading: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFont.bold(21, relativeTo: .title2))
                .foregroundStyle(.primary)

            if let subtitle {
                Text(subtitle)
                    .font(AppFont.regular(14, relativeTo: .subheadline))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
