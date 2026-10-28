import SwiftUI

enum WeatherPalette {
    static let ink = Color(red: 0.055, green: 0.082, blue: 0.153)
    static let deepBlue = Color(red: 0.10, green: 0.16, blue: 0.28)
    static let card = Color(red: 0.15, green: 0.21, blue: 0.34)
    static let cardHighlight = Color(red: 0.24, green: 0.33, blue: 0.48)
    static let ice = Color(red: 0.73, green: 0.91, blue: 0.99)
    static let softBlue = Color(red: 0.56, green: 0.77, blue: 0.91)
    static let muted = Color(red: 0.72, green: 0.78, blue: 0.88)
    static let mint = Color(red: 0.56, green: 0.85, blue: 0.73)
    static let amber = Color(red: 0.97, green: 0.79, blue: 0.49)
    static let hairline = Color.white.opacity(0.13)
}

enum WeatherFormat {
    static func temperature(_ celsius: Double, fahrenheit: Bool, arabic: Bool) -> String {
        let value = fahrenheit ? Int((celsius * 9 / 5 + 32).rounded()) : Int(celsius.rounded())
        let magnitude = localizedNumber(abs(value), arabic: arabic)
        let sign = value < 0 ? "−" : ""
        return "\(sign)\(magnitude)°"
    }

    static func localizedNumber(_ value: Int, arabic: Bool) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: arabic ? "ar" : "en_US")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func hour(_ date: Date, arabic: Bool, timeZoneIdentifier: String? = nil) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: arabic ? "ar" : "en_US")
        if let timeZoneIdentifier, let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            formatter.timeZone = timeZone
        }
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func weekday(_ date: Date, arabic: Bool, timeZoneIdentifier: String? = nil) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: arabic ? "ar" : "en_US")
        if let timeZoneIdentifier, let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            formatter.timeZone = timeZone
        }
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct WeatherBackdrop: View {
    let condition: WeatherCondition

    private var skyColors: [Color] {
        switch condition {
        case .clear: [Color(red: 0.20, green: 0.27, blue: 0.48), Color(red: 0.25, green: 0.28, blue: 0.44), Color(red: 0.06, green: 0.10, blue: 0.19)]
        case .partlyCloudy: [Color(red: 0.11, green: 0.30, blue: 0.48), Color(red: 0.17, green: 0.25, blue: 0.42), Color(red: 0.05, green: 0.09, blue: 0.18)]
        case .cloudy: [Color(red: 0.20, green: 0.29, blue: 0.43), Color(red: 0.14, green: 0.21, blue: 0.34), Color(red: 0.05, green: 0.08, blue: 0.16)]
        case .rain: [Color(red: 0.08, green: 0.20, blue: 0.34), Color(red: 0.10, green: 0.17, blue: 0.29), Color(red: 0.035, green: 0.065, blue: 0.13)]
        case .snow: [Color(red: 0.16, green: 0.35, blue: 0.49), Color(red: 0.12, green: 0.24, blue: 0.39), Color(red: 0.045, green: 0.09, blue: 0.17)]
        case .thunderstorm: [Color(red: 0.19, green: 0.15, blue: 0.34), Color(red: 0.11, green: 0.13, blue: 0.27), Color(red: 0.035, green: 0.055, blue: 0.12)]
        case .fog: [Color(red: 0.25, green: 0.34, blue: 0.43), Color(red: 0.16, green: 0.24, blue: 0.34), Color(red: 0.055, green: 0.09, blue: 0.16)]
        }
    }

    private var stageGlow: Color {
        switch condition {
        case .clear: WeatherPalette.amber
        case .partlyCloudy, .snow: WeatherPalette.ice
        case .cloudy, .rain, .fog: WeatherPalette.softBlue
        case .thunderstorm: Color(red: 0.70, green: 0.61, blue: 0.98)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    LinearGradient(
                        colors: skyColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Circle()
                        .fill(RadialGradient(
                            colors: [stageGlow.opacity(0.34), stageGlow.opacity(0.09), .clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: geometry.size.width * 0.50
                        ))
                        .frame(width: geometry.size.width * 1.02, height: geometry.size.width * 1.02)
                        .offset(x: geometry.size.width * 0.25, y: -geometry.size.height * 0.25)

                    Ellipse()
                        .fill(stageGlow.opacity(condition == .clear ? 0.09 : 0.07))
                        .frame(width: geometry.size.width * 1.2, height: geometry.size.height * 0.22)
                        .blur(radius: 48)
                        .offset(x: CGFloat(sin(time * 0.10)) * 24, y: geometry.size.height * 0.04)

                    Circle()
                        .stroke(.white.opacity(0.075), lineWidth: 1)
                        .frame(width: geometry.size.width * 1.25, height: geometry.size.width * 1.25)
                        .offset(x: geometry.size.width * 0.47, y: geometry.size.height * 0.06)

                    Circle()
                        .stroke(.white.opacity(0.045), lineWidth: 1)
                        .frame(width: geometry.size.width * 0.96, height: geometry.size.width * 0.96)
                        .offset(x: geometry.size.width * 0.47, y: geometry.size.height * 0.06)

                    Canvas { context, size in
                        let width = Double(size.width)
                        let height = Double(size.height)
                        let drift = sin(time * 0.07) * 0.025
                        for index in 0..<4 {
                            let spread = Double(index) * 0.13
                            let topX = width * (0.35 + spread + drift)
                            var beam = Path()
                            beam.move(to: CGPoint(x: topX, y: 0))
                            beam.addLine(to: CGPoint(x: topX + width * 0.22, y: height * 0.72))
                            beam.addLine(to: CGPoint(x: topX + width * 0.31, y: height * 0.72))
                            beam.addLine(to: CGPoint(x: topX + width * 0.08, y: 0))
                            beam.closeSubpath()
                            context.fill(beam, with: .color(stageGlow.opacity(condition == .clear ? 0.025 : 0.012)))
                        }

                        if condition == .snow || condition == .rain {
                            for index in 0..<36 {
                                let seed = Double(index)
                                let speed = condition == .snow ? 16.0 : 58.0
                                let x = (seed * 73.7 + sin(time * 0.27 + seed) * 16)
                                    .truncatingRemainder(dividingBy: max(width, 1))
                                let y = (seed * 47.3 + time * speed)
                                    .truncatingRemainder(dividingBy: max(height, 1))
                                if condition == .snow {
                                    let diameter = 2.0 + (seed.truncatingRemainder(dividingBy: 3))
                                    let rect = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(diameter), height: CGFloat(diameter))
                                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.31)))
                                } else {
                                    var drop = Path()
                                    drop.move(to: CGPoint(x: CGFloat(x), y: CGFloat(y)))
                                    drop.addLine(to: CGPoint(x: CGFloat(x - 3), y: CGFloat(y + 12)))
                                    context.stroke(drop, with: .color(WeatherPalette.ice.opacity(0.17)), lineWidth: 1)
                                }
                            }
                        }
                    }

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.09), .black.opacity(0.30)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct WeatherStageOrb: View {
    let condition: WeatherCondition

    private var glow: Color {
        switch condition {
        case .clear: WeatherPalette.amber
        case .partlyCloudy, .snow: WeatherPalette.ice
        case .cloudy, .rain, .fog: WeatherPalette.softBlue
        case .thunderstorm: Color(red: 0.76, green: 0.66, blue: 1.0)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [glow.opacity(0.34), glow.opacity(0.08), .clear],
                    center: .center,
                    startRadius: 5,
                    endRadius: 68
                ))
            Circle().stroke(.white.opacity(0.26), lineWidth: 1)
            Circle()
                .trim(from: 0.08, to: 0.88)
                .stroke(
                    AngularGradient(colors: [.white.opacity(0.75), glow.opacity(0.7), .clear], center: .center),
                    style: StrokeStyle(lineWidth: 1.7, lineCap: .round)
                )
                .rotationEffect(.degrees(-76))
                .padding(4)
            Circle().stroke(.white.opacity(0.10), lineWidth: 1).padding(13)
            Image(systemName: condition.symbolName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(WeatherPalette.ice, WeatherPalette.amber)
                .font(.system(size: 39, weight: .light))
                .symbolEffect(.pulse, options: .repeating)
        }
        .frame(width: 116, height: 116)
        .shadow(color: glow.opacity(0.20), radius: 24, y: 8)
        .accessibilityHidden(true)
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    let interactive: Bool

    init(interactive: Bool = false, @ViewBuilder content: () -> Content) {
        self.interactive = interactive
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if interactive {
            content
                .padding(18)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        } else {
            content
                .padding(18)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        }
    }
}

struct WeatherGlassEffect<S: Shape>: ViewModifier {
    let shape: S
    var interactive = false
    var tint: Color? = nil

    @ViewBuilder
    func body(content: Content) -> some View {
        if let tint {
            if interactive {
                content.glassEffect(.regular.tint(tint).interactive(), in: shape)
            } else {
                content.glassEffect(.regular.tint(tint), in: shape)
            }
        } else if interactive {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content.glassEffect(.regular, in: shape)
        }
    }
}

extension View {
    func weatherGlass<S: Shape>(in shape: S, interactive: Bool = false, tint: Color? = nil) -> some View {
        modifier(WeatherGlassEffect(shape: shape, interactive: interactive, tint: tint))
    }
}

struct SectionHeading: View {
    let eyebrow: String
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(WeatherPalette.muted.opacity(0.85))
                Text(title)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(WeatherPalette.ice)
            }
        }
    }
}

struct WeatherSourceNote: View {
    @ObservedObject var model: WeatherViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text(model.isArabic ? "مصدر بيانات الطقس:" : "Weather data:")
                Link("Open-Meteo", destination: URL(string: "https://open-meteo.com/")!)
                Text("·")
                Link("CC BY 4.0", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
            }
            .foregroundStyle(WeatherPalette.muted)
            .tint(WeatherPalette.ice)

            if model.hasLiveData, let updatedAt = model.lastUpdatedAt {
                Text(model.isArabic
                     ? "آخر قراءة: \(WeatherFormat.hour(updatedAt, arabic: true, timeZoneIdentifier: model.snapshot.timezoneIdentifier))"
                     : "Latest reading: \(WeatherFormat.hour(updatedAt, arabic: false, timeZoneIdentifier: model.snapshot.timezoneIdentifier))")
                    .foregroundStyle(WeatherPalette.muted.opacity(0.85))
            }

            if model.refreshFailed, model.hasLiveData {
                Text(model.isArabic
                     ? "تعذّر التحديث؛ نعرض آخر بيانات ناجحة."
                     : "Couldn't refresh; showing the last successful data.")
                    .foregroundStyle(WeatherPalette.amber)
            }
        }
        .font(.system(size: 10, weight: .regular, design: .rounded))
    }
}

struct WeatherConnectionStateView: View {
    @ObservedObject var model: WeatherViewModel

    var body: some View {
        VStack {
            Spacer(minLength: 18)
            GlassCard {
                VStack(spacing: 13) {
                    Image(systemName: model.isRefreshing ? "cloud.sun.fill" : "wifi.exclamationmark")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(model.isRefreshing ? WeatherPalette.ice : WeatherPalette.amber)

                    Text(model.snapshot.location.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    if model.isRefreshing {
                        ProgressView()
                            .tint(WeatherPalette.ice)
                        Text(model.isArabic ? "جارٍ جلب الطقس من الإنترنت…" : "Fetching weather from the internet…")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(WeatherPalette.muted)
                    } else {
                        Text(model.isArabic
                             ? "تعذّر جلب الطقس الآن. تحقق من الاتصال ثم أعد المحاولة."
                             : "Live weather couldn't be loaded. Check your connection and try again.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(WeatherPalette.muted)
                            .multilineTextAlignment(.center)

                        Button { model.refresh() } label: {
                            Label(model.isArabic ? "إعادة المحاولة" : "Try again", systemImage: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(WeatherPalette.ink)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                                .background(WeatherPalette.ice, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    WeatherSourceNote(model: model)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.top, 3)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 18)
            Spacer(minLength: 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}
