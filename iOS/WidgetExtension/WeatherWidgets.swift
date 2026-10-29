import SwiftUI
import WidgetKit

struct WeatherWidgetEntry: TimelineEntry {
    let date: Date
    let data: WeatherWidgetData?
}

struct WeatherWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherWidgetEntry {
        WeatherWidgetEntry(date: .now, data: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherWidgetEntry) -> Void) {
        completion(WeatherWidgetEntry(date: .now, data: WeatherWidgetStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherWidgetEntry>) -> Void) {
        let cached = WeatherWidgetStore.load()
        let location = cached?.location ?? .baghdad
        let preferences = WeatherWidgetStore.preferences()
        let shouldRefresh = cached.map { Date().timeIntervalSince($0.observedAt) > 30 * 60 } ?? true

        Task {
            var latest = cached
            if shouldRefresh {
                if let snapshot = try? await OpenMeteoWeatherProvider().forecast(for: location) {
                    WeatherWidgetStore.save(
                        snapshot: snapshot,
                        isArabic: preferences.isArabic,
                        usesFahrenheit: preferences.usesFahrenheit
                    )
                    latest = WeatherWidgetStore.load()
                }
            }

            let entry = WeatherWidgetEntry(date: .now, data: latest)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(45 * 60)))
            completion(timeline)
        }
    }
}

struct MuznWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WeatherWidgetEntry

    var body: some View {
        Group {
            if let data = entry.data {
                weatherContent(for: data)
            } else {
                unavailableContent
            }
        }
        // WidgetKit applies its own platform glass and tint. Keep the background
        // transparent so the system can compose the widget naturally.
        .containerBackground(for: .widget) { Color.clear }
        .environment(\.layoutDirection, widgetIsArabic ? .rightToLeft : .leftToRight)
    }

    private var widgetIsArabic: Bool {
        entry.data?.isArabic ?? WeatherWidgetStore.preferences().isArabic
    }

    @ViewBuilder
    private func weatherContent(for data: WeatherWidgetData) -> some View {
        switch family {
        case .systemSmall:
            smallHomeWidget(for: data)
        case .systemMedium, .systemLarge, .systemExtraLarge:
            mediumHomeWidget(for: data)
        case .accessoryInline:
            Label(temperature(for: data), systemImage: conditionSymbol(for: data))
                .symbolRenderingMode(.monochrome)
                .accessibilityLabel("\(data.location.name), \(temperature(for: data)), \(conditionName(for: data))")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: conditionSymbol(for: data))
                        .symbolRenderingMode(.monochrome)
                        .font(.system(size: 13, weight: .medium))
                    Text(temperature(for: data))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(data.location.name), \(temperature(for: data)), \(conditionName(for: data))")
        case .accessoryRectangular:
            lockScreenRectangular(for: data)
        @unknown default:
            smallHomeWidget(for: data)
        }
    }

    @ViewBuilder
    private var unavailableContent: some View {
        let isArabic = widgetIsArabic
        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: "cloud")
                    .font(.system(size: 22, weight: .regular))
                Text("مُزن")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Text(isArabic ? "افتح التطبيق لتحميل الطقس" : "Open the app to load weather")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.vertical, 2)
        case .systemMedium, .systemLarge, .systemExtraLarge:
            Label(
                isArabic ? "افتح مُزن لتحميل بيانات الطقس" : "Open Muzn to load weather",
                systemImage: "cloud"
            )
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        case .accessoryInline:
            Label(isArabic ? "افتح مُزن" : "Open Muzn", systemImage: "cloud")
                .symbolRenderingMode(.monochrome)
                .accessibilityLabel(isArabic ? "افتح مُزن لتحميل الطقس" : "Open Muzn to load weather")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "cloud")
                    .font(.system(size: 15, weight: .medium))
            }
            .accessibilityLabel(isArabic ? "افتح مُزن لتحميل الطقس" : "Open Muzn to load weather")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                Text("مُزن")
                    .font(.system(size: 12, weight: .semibold))
                Text(isArabic ? "افتح التطبيق لتحميل الطقس" : "Open the app to load weather")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.secondary)
            }
        @unknown default:
            Label(isArabic ? "افتح مُزن" : "Open Muzn", systemImage: "cloud")
        }
    }

    private func smallHomeWidget(for data: WeatherWidgetData) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(data.location.name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            HStack(spacing: 5) {
                Image(systemName: conditionSymbol(for: data))
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 22, weight: .regular))
                Text(temperature(for: data))
                    .font(.system(size: 36, weight: .light, design: .rounded))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            Text(conditionName(for: data))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Label(high(for: data), systemImage: "arrow.up")
                Label(low(for: data), systemImage: "arrow.down")
            }
            .font(.system(size: 9, weight: .medium, design: .rounded))
            .lineLimit(1)
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 2)
    }

    private func mediumHomeWidget(for data: WeatherWidgetData) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(data.location.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                HStack(spacing: 7) {
                    Image(systemName: conditionSymbol(for: data))
                        .symbolRenderingMode(.monochrome)
                        .font(.system(size: 27, weight: .regular))
                    Text(temperature(for: data))
                        .font(.system(size: 43, weight: .light, design: .rounded))
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                Text(conditionName(for: data))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 9) {
                detailRow(title: data.isArabic ? "العظمى · الصغرى" : "HIGH · LOW", value: "\(high(for: data)) · \(low(for: data))")
                detailRow(title: data.isArabic ? "المطر" : "RAIN", value: "\(localized(data.precipitationProbability, arabic: data.isArabic))%")
                detailRow(title: data.isArabic ? "الرطوبة" : "HUMIDITY", value: "\(localized(data.humidityPercent, arabic: data.isArabic))%")
                detailRow(title: data.isArabic ? "الرياح" : "WIND", value: "\(localized(Int(data.windKPH.rounded()), arabic: data.isArabic)) \(data.isArabic ? "كم/س" : "km/h")")
            }
            .frame(maxWidth: 122, alignment: .leading)
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 2)
    }

    private func lockScreenRectangular(for data: WeatherWidgetData) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(data.location.name)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
            HStack(spacing: 6) {
                Image(systemName: conditionSymbol(for: data))
                    .symbolRenderingMode(.monochrome)
                Text(temperature(for: data))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(conditionName(for: data))
                    .lineLimit(1)
            }
            .font(.system(size: 11, weight: .medium))
            Text(data.isArabic ? "العظمى \(high(for: data)) · الصغرى \(low(for: data))" : "High \(high(for: data)) · Low \(low(for: data))")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.secondary)
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 1)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
    }

    private func conditionSymbol(for data: WeatherWidgetData) -> String { data.condition.outlineSymbolName }
    private func conditionName(for data: WeatherWidgetData) -> String { data.condition.localizedLabel(arabic: data.isArabic) }
    private func temperature(for data: WeatherWidgetData) -> String {
        WeatherFormat.temperature(data.temperatureC, fahrenheit: data.usesFahrenheit, arabic: data.isArabic)
    }
    private func high(for data: WeatherWidgetData) -> String {
        WeatherFormat.temperature(data.highC, fahrenheit: data.usesFahrenheit, arabic: data.isArabic)
    }
    private func low(for data: WeatherWidgetData) -> String {
        WeatherFormat.temperature(data.lowC, fahrenheit: data.usesFahrenheit, arabic: data.isArabic)
    }

    private func localized(_ value: Int, arabic: Bool) -> String {
        WeatherFormat.localizedNumber(value, arabic: arabic)
    }
}

struct MuznWeatherWidget: Widget {
    let kind = "MuznWeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherWidgetProvider()) { entry in
            MuznWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("مُزن · الطقس")
        .description("الطقس الحالي على الشاشة الرئيسية وشاشة القفل.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct MuznWidgetBundle: WidgetBundle {
    var body: some Widget {
        MuznWeatherWidget()
    }
}
