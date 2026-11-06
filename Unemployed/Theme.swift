import SwiftUI

/// Look & feel from the "Unemployed" logo: near-black background, electric lime,
/// heavy tight type, and arrows everywhere.
/// Layout values still come from the Figma file (Onboarding-workflow).
enum Theme {
    // MARK: Fonts
    // Body text uses Inter (falls back to the system font if Inter isn't added).
    static func semibold(_ size: CGFloat) -> Font { .custom("Inter-SemiBold", size: size) }
    static func regular(_ size: CGFloat) -> Font  { .custom("Inter-Regular", size: size) }
    static func bold(_ size: CGFloat) -> Font     { .custom("Inter-Bold", size: size) }
    /// Blocky headline font: heavy, tight sans.
    static func display(_ size: CGFloat) -> Font  { .system(size: size, weight: .black, design: .default) }

    // MARK: Brand palette (matches the logo)
    static let lime       = Color(hex: 0xD4FF3A)   // brand accent, buttons, arrows
    static let onLime     = Color(hex: 0x121212)   // text/icons sitting on lime
    static let pillWhite  = Color(hex: 0xFFFFFF)   // secondary pill (like "match")

    // MARK: Palette
    static let background = Color(hex: 0x121212)   // near-black
    static let card       = Color(hex: 0x1D1D21)   // raised surfaces, fields
    static let forest     = lime                   // primary (old name kept so screens still compile)
    static let moss       = lime                   // tints (nav back arrows, tab bar)
    static let sage       = Color(hex: 0x34343B)   // chips / tracks / borders
    static let ink        = Color(hex: 0xF4F4F0)   // main text on the dark background
    static let onDark     = onLime                 // text on the primary fill (now lime, so dark text)

    // MARK: Component tokens (same names the screens already use)
    static let logoCircle        = lime
    static let welcomeButtonFill = lime
    static let authButtonFill    = lime
    static let ctaFill           = lime
    static let softFill          = Color.white.opacity(0.06)
    static let softBorder        = lime.opacity(0.25)
    static let placeholderGray   = Color(hex: 0x85828F)
    static let skipGray          = Color(hex: 0xB8B5C2)
    static let chipGray          = sage
}

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue:  Double(hex & 0xFF) / 255)
    }
}


// The arrow pieces used across the app: the app mark, the swoosh wordmark,
// a reusable arrow line, and a little press animation for pill buttons.

// MARK: - Arrow-u (same geometry as the logo / app icon, drawn in a 100x100 box)
struct ArrowUMark: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 100
        let ox = rect.midX - 50 * s, oy = rect.midY - 50 * s
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }

        var path = Path()
        path.move(to: p(30, 34))
        path.addArc(tangent1End: p(30, 76), tangent2End: p(70, 76), radius: 20 * s)
        path.addArc(tangent1End: p(70, 76), tangent2End: p(70, 26), radius: 20 * s)
        path.addLine(to: p(70, 26))
        path.move(to: p(58, 36))
        path.addLine(to: p(70, 24))
        path.addLine(to: p(82, 36))
        return path
    }
}

/// Lime rounded square with the black arrow-u, like the app icon.
struct AppMark: View {
    var size: CGFloat = 200
    /// 0...1, how much of the arrow-u is drawn (down the left side, swoop up, then the head).
    var draw: CGFloat = 1

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                .fill(Theme.lime)
            ArrowUMark()
                .trim(from: 0, to: draw)
                .stroke(Theme.onLime, style: StrokeStyle(lineWidth: size * 0.77 * 0.11,
                                                         lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.77, height: size * 0.77)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Arrow line (a straight line ending in a chevron)
struct ArrowLine: Shape {
    enum Direction { case left, right }
    var direction: Direction = .right
    var headSize: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        let y = rect.midY
        let tail = CGPoint(x: direction == .right ? rect.minX : rect.maxX, y: y)
        let tip  = CGPoint(x: direction == .right ? rect.maxX : rect.minX, y: y)
        let back = direction == .right ? -headSize : headSize

        var path = Path()
        path.move(to: tail)            // drawn tail -> tip so .trim "grows" toward the arrow
        path.addLine(to: tip)
        path.move(to: CGPoint(x: tip.x + back, y: y - headSize))
        path.addLine(to: tip)
        path.addLine(to: CGPoint(x: tip.x + back, y: y + headSize))
        return path
    }
}

// MARK: - Swoosh wordmark: "Unemployed" with the U rising into an arrow over the
// word and the y's tail turning into an arrow under it.
struct ArrowWordmark: View {
    var size: CGFloat = 46
    /// 0...1, how much of the two swoosh arrows is drawn (animate this).
    var draw: CGFloat = 1
    var color: Color = Theme.lime

    private var lw: CGFloat { size * 0.14 }     // stroke weight, matched to the black font
    private var uW: CGFloat { size * 0.78 }
    private var uH: CGFloat { size * 1.10 }     // taller than the text, so the U sets the top
    private var yW: CGFloat { size * 0.56 }
    private var xH: CGFloat { size * 0.53 }     // x-height
    private var drop: CGFloat { size * 0.40 }   // underline depth below the baseline
    private var ext: CGFloat { size * 0.55 }    // how far the arrows run past the word
    private var head: CGFloat { size * 0.20 }

    private var stroke: StrokeStyle { StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round) }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                UGlyph(capHeight: size * 0.71, lineWidth: lw)
                    .stroke(color, style: stroke)
                    .frame(width: uW, height: uH)
                    .alignmentGuide(.lastTextBaseline) { $0[.bottom] }
                    .padding(.trailing, -size * 0.10)
                Text("nemplo")
                YGlyph(lineWidth: lw, drop: drop, color: color)
                    .frame(width: yW, height: xH)
                    .alignmentGuide(.lastTextBaseline) { $0[.bottom] }
            }
            // Bottom swoosh: starts where the y's tail ends and runs left past the U.
            .overlay(alignment: .topLeading) {
                GeometryReader { g in
                    let endX = g.size.width - yW + 2
                    ArrowLine(direction: .left, headSize: head)
                        .trim(from: 0, to: draw)
                        .stroke(color, style: stroke)
                        .frame(width: endX + ext, height: head * 2)
                        .position(x: (endX - ext) / 2, y: uH + drop)
                }
            }
            Text("ed")
        }
        .font(Theme.display(size))
        .tracking(-size * 0.02)
        .foregroundStyle(color)
        // Top swoosh: continues from the U's right side and runs right past the "d".
        .overlay(alignment: .topLeading) {
            GeometryReader { g in
                let startX = uW - 2
                let length = g.size.width - startX + ext
                ArrowLine(direction: .right, headSize: head)
                    .trim(from: 0, to: draw)
                    .stroke(color, style: stroke)
                    .frame(width: length, height: head * 2)
                    .position(x: startX + length / 2, y: lw / 2)
            }
        }
        .padding(.horizontal, ext + head * 0.5)
        .padding(.bottom, drop)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Unemployed")
    }
}

/// Capital U whose right stem rises and turns right into the top swoosh.
private struct UGlyph: Shape {
    var capHeight: CGFloat
    var lineWidth: CGFloat

    func path(in r: CGRect) -> Path {
        let half = lineWidth / 2
        let left = r.minX + half
        let right = r.minX + r.width * 0.74
        let bottom = r.maxY - half
        let top = r.maxY - capHeight + half
        let over = r.minY + half
        let bowl = (right - left) / 2
        let corner = (r.maxX - right) * 0.9

        var p = Path()
        p.move(to: CGPoint(x: left, y: top))
        p.addArc(tangent1End: CGPoint(x: left, y: bottom), tangent2End: CGPoint(x: right, y: bottom), radius: bowl)
        p.addArc(tangent1End: CGPoint(x: right, y: bottom), tangent2End: CGPoint(x: right, y: over), radius: bowl)
        p.addArc(tangent1End: CGPoint(x: right, y: over), tangent2End: CGPoint(x: r.maxX, y: over), radius: corner)
        p.addLine(to: CGPoint(x: r.maxX + 1, y: over))
        return p
    }
}

/// A normal y: two arms with flat tops, the right one continuing down into a tail
/// that curves left into the bottom swoosh. Its frame is the x-height box.
private struct YGlyph: View {
    var lineWidth: CGFloat
    var drop: CGFloat
    var color: Color

    var body: some View {
        ZStack {
            YArms(lineWidth: lineWidth)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt, lineJoin: .miter))
                .clipped()   // flat tops cut at the x-height, like the font
            YTail(lineWidth: lineWidth, drop: drop)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
    }

    static func points(in r: CGRect, lineWidth: CGFloat) -> (leftTop: CGPoint, rightTop: CGPoint, joint: CGPoint) {
        (CGPoint(x: r.minX + lineWidth * 0.6, y: r.minY - lineWidth),
         CGPoint(x: r.maxX - lineWidth * 0.6, y: r.minY - lineWidth),
         CGPoint(x: r.minX + r.width * 0.48, y: r.maxY - lineWidth * 0.15))
    }
}

private struct YArms: Shape {
    var lineWidth: CGFloat
    func path(in r: CGRect) -> Path {
        let pts = YGlyph.points(in: r, lineWidth: lineWidth)
        var p = Path()
        p.move(to: pts.leftTop);  p.addLine(to: pts.joint)
        p.move(to: pts.rightTop); p.addLine(to: pts.joint)
        return p
    }
}

private struct YTail: Shape {
    var lineWidth: CGFloat
    var drop: CGFloat
    func path(in r: CGRect) -> Path {
        let pts = YGlyph.points(in: r, lineWidth: lineWidth)
        let slope = (pts.joint.x - pts.rightTop.x) / (pts.joint.y - pts.rightTop.y)
        let tailY = r.maxY + drop
        let hitX = pts.joint.x + slope * (tailY - pts.joint.y)

        var p = Path()
        p.move(to: pts.joint)
        p.addArc(tangent1End: CGPoint(x: hitX, y: tailY),
                 tangent2End: CGPoint(x: r.minX - 100, y: tailY),
                 radius: drop * 0.3)
        p.addLine(to: CGPoint(x: r.minX - 2, y: tailY))
        return p
    }
}

// MARK: - Press feedback for pill buttons
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview("Arrow kit") {
    VStack(spacing: 40) {
        AppMark(size: 160)
        ArrowWordmark(size: 46)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
}
