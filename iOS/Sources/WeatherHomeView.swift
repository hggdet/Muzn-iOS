import SwiftUI

struct WeatherHomeView: View {
    @ObservedObject var model: WeatherViewModel
    @State private var showingLocations = false
    @State private var selectedHourIndex = 0
    @State private var selectedChartMetric: HourlyChartMetric = .rainChance

    var body: some View {
        NavigationStack {
            ZStack {
                WeatherBackdrop(condition: model.snapshot.current.condition)

                VStack(spacing: 0) {
                    if model.refreshFailed, model.hasLiveData {
                        Label(
                            model.isArabic ? "تعذّر التحديث؛ نعرض آخر قراءة ناجحة." : "Refresh failed; showing the last successful reading.",
                            systemImage: "wifi.exclamationmark"
                        )
                        .font(WeatherTypography.font(10, weight: .medium, text: model.isArabic
                            ? "تعذّر التحديث؛ نعرض آخر قراءة ناجحة."
                            : "Refresh failed; showing the last successful reading."))
                        .foregroundStyle(WeatherPalette.amber)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 7)
                    }
                    Group {
                        switch model.selectedTab {
                        case .today:
                            todayPage
                        case .forecast:
                            ForecastView(model: model)
                        case .settings:
                            SettingsView(model: model, onManageCities: { showingLocations = true })
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    capsuleNavigation
                }
            }
            .navigationTitle(model.snapshot.location.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(model.snapshot.location.name)
                        .font(WeatherTypography.font(15, weight: .semibold, text: model.snapshot.location.name))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { model.refresh() } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(model.isRefreshing ? WeatherPalette.muted : WeatherPalette.ice)
                            .symbolEffect(.rotate, isActive: model.isRefreshing)
                    }
                    .disabled(model.isRefreshing)
                    .accessibilityLabel(model.isArabic ? "تحديث الطقس" : "Refresh weather")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingLocations = true } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(WeatherPalette.ice)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(model.isArabic ? "اختيار المدينة" : "Choose city")
                }
            }
        }
        .environment(\.layoutDirection, model.isArabic ? .rightToLeft : .leftToRight)
        .sheet(isPresented: $showingLocations) {
            LocationPickerSheet(model: model)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task { model.refresh() }
    }

    private var capsuleNavigation: some View {
        HStack(spacing: 4) {
            navigationButton(.today, title: model.isArabic ? "اليوم" : "Today", symbol: "sun.max")
            navigationButton(.forecast, title: model.isArabic ? "التوقعات" : "Forecast", symbol: "calendar")
            navigationButton(.settings, title: model.isArabic ? "الإعدادات" : "Settings", symbol: "slider.horizontal.3")
        }
        .padding(6)
        .weatherGlass(in: Capsule(), tint: WeatherPalette.deepBlue.opacity(0.42))
        .padding(.horizontal, 30)
        .padding(.top, 7)
        .padding(.bottom, 8)
    }

    private func navigationButton(_ tab: MainTab, title: String, symbol: String) -> some View {
        let selected = model.selectedTab == tab
        return Button {
            withAnimation(.snappy(duration: 0.22)) { model.selectedTab = tab }
        } label: {
            Label {
                Text(title)
            } icon: {
                Image(systemName: symbol)
                    .symbolRenderingMode(.monochrome)
            }
                .font(WeatherTypography.font(11, weight: .semibold, text: title))
                .foregroundStyle(selected ? WeatherPalette.ink : WeatherPalette.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .weatherGlass(in: Capsule(), interactive: true, tint: selected ? WeatherPalette.ice : nil)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var todayPage: some View {
        Group {
            if model.hasLiveData {
                ScrollView {
                    GlassEffectContainer(spacing: 0) {
                        VStack(alignment: .leading, spacing: 17) {
                            currentWeatherHero
                            todayDetailsPanel
                            sampleNotice
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 3)
                        .padding(.bottom, 22)
                    }
                }
                .scrollIndicators(.hidden)
            } else {
                WeatherConnectionStateView(model: model)
            }
        }
    }

    private var currentWeatherHero: some View {
        GlassCard {
            VStack(alignment: .center, spacing: 15) {
                HStack {
                    Label(model.isArabic ? "الطقس الآن" : "CURRENT WEATHER", systemImage: "sparkles")
                        .font(WeatherTypography.font(10, weight: .bold, text: model.isArabic ? "الطقس الآن" : "CURRENT WEATHER"))
                        .tracking(model.isArabic ? 0 : 0.8)
                        .foregroundStyle(WeatherPalette.ice)
                    Spacer()
                    HStack(spacing: 5) {
                        Circle().fill(WeatherPalette.mint).frame(width: 5, height: 5)
                        Text(model.isArabic ? "مباشر" : "LIVE")
                            .font(WeatherTypography.font(9, weight: .bold, text: model.isArabic ? "مباشر" : "LIVE"))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .weatherGlass(in: Capsule())
                }

                VStack(spacing: 3) {
                    Text(model.snapshot.location.name)
                        .font(WeatherTypography.font(14, weight: .medium, text: model.snapshot.location.name))
                        .foregroundStyle(WeatherPalette.muted)
                        .lineLimit(1)
                    WeatherStageOrb(condition: model.snapshot.current.condition)
                        .scaleEffect(0.70)
                        .frame(width: 81, height: 78)
                        .padding(.top, 1)
                    Text(WeatherFormat.temperature(model.snapshot.current.temperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                        .font(WeatherTypography.font(100, weight: .light, text: WeatherFormat.temperature(model.snapshot.current.temperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic)))
                        .tracking(model.isArabic ? -2 : -6)
                        .contentTransition(.numericText())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .padding(.top, -14)
                    Text(model.snapshot.current.condition.localizedLabel(arabic: model.isArabic))
                        .font(WeatherTypography.font(15, weight: .semibold, text: model.snapshot.current.condition.localizedLabel(arabic: model.isArabic)))
                        .foregroundStyle(.white.opacity(0.94))
                    if !model.snapshot.hourly.isEmpty {
                        hourlyCircleStrip(
                            hours: Array(model.snapshot.hourly.prefix(12)),
                            selectedIndex: selectedHourIndex
                        )
                        .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var todayDetailsPanel: some View {
        let hours = Array(model.snapshot.hourly.prefix(12))
        let selectedIndex = hours.isEmpty ? 0 : min(max(selectedHourIndex, 0), hours.count - 1)
        let selectedHour = hours.indices.contains(selectedIndex) ? hours[selectedIndex] : nil

        return GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeading(
                    eyebrow: model.isArabic ? "تفاصيل اليوم" : "TODAY AT A GLANCE",
                    title: model.isArabic ? "مؤشرات الطقس" : "Weather details"
                )

                LazyVGrid(
                    columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
                    alignment: .leading,
                    spacing: 14
                ) {
                    connectedMetric(
                        symbol: "drop",
                        title: model.isArabic ? "احتمال المطر" : "RAIN CHANCE",
                        value: "\(WeatherFormat.localizedNumber(selectedHour?.precipitationProbability ?? 0, arabic: model.isArabic))%"
                    )
                    connectedMetric(
                        symbol: "sun.max",
                        title: model.isArabic ? "الأشعة فوق البنفسجية" : "UV INDEX",
                        value: "\(WeatherFormat.localizedNumber(model.snapshot.uvIndex, arabic: model.isArabic)) · \(uvIndexLabel)"
                    )
                    connectedMetric(
                        symbol: "humidity",
                        title: model.isArabic ? "الرطوبة" : "HUMIDITY",
                        value: "\(WeatherFormat.localizedNumber(model.snapshot.humidityPercent, arabic: model.isArabic))%"
                    )
                    connectedMetric(
                        symbol: "wind",
                        title: model.isArabic ? "هبات الرياح" : "WIND GUSTS",
                        value: "\(WeatherFormat.localizedNumber(model.snapshot.windGustKPH, arabic: model.isArabic)) \(model.isArabic ? "كم/س" : "km/h")"
                    )
                    connectedMetric(
                        symbol: "aqi.medium",
                        title: model.isArabic ? "جودة الهواء" : "AIR QUALITY",
                        value: model.snapshot.airQualityIndex.map { "\(WeatherFormat.localizedNumber($0, arabic: model.isArabic)) · \(airQualityLabel)" } ?? (model.isArabic ? "غير متاح" : "Unavailable")
                    )
                    connectedMetric(
                        symbol: "thermometer.medium",
                        title: model.isArabic ? "المحسوسة" : "FEELS LIKE",
                        value: WeatherFormat.temperature(model.snapshot.current.apparentTemperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic)
                    )
                    connectedMetric(
                        symbol: "wind",
                        title: model.isArabic ? "سرعة الرياح" : "WIND SPEED",
                        value: "\(WeatherFormat.localizedNumber(Int(model.snapshot.current.windKPH.rounded()), arabic: model.isArabic)) \(model.isArabic ? "كم/س" : "km/h")"
                    )
                }

                HStack {
                    Text(model.isArabic ? "وحدة الحرارة" : "TEMPERATURE UNIT")
                        .font(WeatherTypography.font(10, weight: .semibold, text: model.isArabic ? "وحدة الحرارة" : "TEMPERATURE UNIT"))
                        .tracking(model.isArabic ? 0 : 0.7)
                        .foregroundStyle(WeatherPalette.muted)
                    Spacer()
                    Button { model.usesFahrenheit.toggle() } label: {
                        Label(model.usesFahrenheit ? "°F" : "°C", systemImage: "thermometer.medium")
                            .font(WeatherTypography.font(12, weight: .semibold, text: model.usesFahrenheit ? "°F" : "°C"))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .weatherGlass(in: Capsule(), interactive: true, tint: WeatherPalette.ice.opacity(0.08))
                    .accessibilityLabel(model.isArabic ? "تغيير وحدة الحرارة" : "Change temperature unit")
                }

                if !hours.isEmpty {
                    VStack(alignment: .leading, spacing: 11) {
                        HStack {
                            Text(model.isArabic ? "الساعات القادمة" : "COMING HOURS")
                                .font(WeatherTypography.font(10, weight: .bold, text: model.isArabic ? "الساعات القادمة" : "COMING HOURS"))
                                .foregroundStyle(WeatherPalette.muted)
                            Spacer()
                            if let selectedHour {
                                Text(selectedChartMetric.valueText(for: selectedHour, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                                    .font(WeatherTypography.font(11, weight: .semibold, text: selectedChartMetric.valueText(for: selectedHour, fahrenheit: model.usesFahrenheit, arabic: model.isArabic)))
                                    .foregroundStyle(WeatherPalette.ice)
                            }
                        }

                        Picker(model.isArabic ? "مؤشر الطقس" : "Weather metric", selection: $selectedChartMetric) {
                            ForEach(HourlyChartMetric.allCases) { metric in
                                Text(metric.title(arabic: model.isArabic))
                                    .font(WeatherTypography.font(10, weight: .semibold, text: metric.title(arabic: model.isArabic)))
                                    .tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel(model.isArabic ? "مؤشر الرسم الساعي" : "Hourly chart metric")

                        HourlyTrendChart(
                            hours: hours,
                            metric: selectedChartMetric,
                            selectedIndex: selectedIndex,
                            fahrenheit: model.usesFahrenheit,
                            arabic: model.isArabic,
                            timeZoneIdentifier: model.snapshot.timezoneIdentifier
                        ) { index in
                            withAnimation(.snappy(duration: 0.13)) { selectedHourIndex = index }
                        }
                        .frame(height: 112)

                    }
                }

                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 9) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(WeatherPalette.ice)
                        Text(outfitCardTitle)
                            .font(WeatherTypography.font(13, weight: .semibold, text: outfitCardTitle))
                            .foregroundStyle(.white)
                        Spacer(minLength: 0)
                        feedbackButton(.warmer, title: model.isArabic ? "أدفأ" : "Warmer", symbol: "plus")
                        feedbackButton(.lighter, title: model.isArabic ? "أخف" : "Lighter", symbol: "minus")
                    }
                    Text(outfitSuggestion)
                        .font(WeatherTypography.font(11, weight: .regular, text: outfitSuggestion))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func connectedMetric(symbol: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .symbolRenderingMode(.monochrome)
                .font(WeatherTypography.font(9, weight: .bold, text: title))
                .foregroundStyle(WeatherPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(WeatherTypography.font(12, weight: .semibold, text: value))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var outfitCardTitle: String {
        model.isArabic ? "ماذا يُناسبك اليوم؟" : "What to wear today"
    }

    private var outfitSuggestion: String {
        let apparent = model.snapshot.current.apparentTemperatureC
        if model.outfitFeedback == .warmer {
            return model.isArabic
                ? "أضف طبقة دافئة أخرى، مثل سترة خفيفة ووشاح. اختر حذاءً مريحًا يناسب حالة الطقس."
                : "Add one warmer layer, such as a light jacket and scarf. Choose comfortable shoes suited to the conditions."
        }
        if model.outfitFeedback == .lighter {
            return model.isArabic
                ? "يمكنك تخفيف طبقة واحدة، مع الاحتفاظ بطبقة خفيفة تحسبًا لتغيّر الطقس."
                : "You can drop one layer, while keeping something light nearby in case conditions change."
        }
        if apparent <= -5 {
            return model.isArabic
                ? "معطف شتوي وطبقات حرارية مع قبعة وقفازات تساعدك على البقاء دافئًا."
                : "A winter coat with thermal layers, a hat and gloves should help you stay warm."
        } else if apparent <= 10 {
            return model.isArabic
                ? "معطف خفيف وطبقة مريحة خياران مناسبان. خذ طبقة إضافية إذا بقيت خارجًا طويلًا."
                : "A light coat and a comfortable layer should work well. Bring an extra layer if you will be out for long."
        } else if apparent <= 24 {
            return model.isArabic
                ? "الملابس الخفيفة المريحة مناسبة غالبًا. خذ سترة خفيفة للمساء."
                : "Light, comfortable clothes should be fine. Bring a light jacket for later."
        }
        return model.isArabic
            ? "اختر ملابس خفيفة تسمح بالتهوية، واشرب الماء بانتظام في الحر."
            : "Choose breathable, lightweight clothes, and remember to drink water in the heat."
    }

    private func feedbackButton(_ feedback: OutfitFeedback, title: String, symbol: String) -> some View {
        let selected = model.outfitFeedback == feedback
        return Button { withAnimation(.easeInOut(duration: 0.18)) { model.outfitFeedback = feedback } } label: {
            Label(title, systemImage: symbol)
                .font(WeatherTypography.font(10, weight: .semibold, text: title))
                    .foregroundStyle(selected ? WeatherPalette.ink : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
            .weatherGlass(in: Capsule(), interactive: true, tint: selected ? WeatherPalette.ice : nil)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityLabel(title)
    }

    private func hourlyCircleStrip(hours: [HourlyForecast], selectedIndex: Int) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                    let selected = index == selectedIndex
                    Button {
                        withAnimation(.snappy(duration: 0.16)) { selectedHourIndex = index }
                    } label: {
                        VStack(spacing: 7) {
                            Text(index == 0 ? (model.isArabic ? "الآن" : "Now") : WeatherFormat.hour(hour.time, arabic: model.isArabic, timeZoneIdentifier: model.snapshot.timezoneIdentifier))
                                .font(WeatherTypography.font(9, weight: .semibold, text: index == 0 ? (model.isArabic ? "الآن" : "Now") : WeatherFormat.hour(hour.time, arabic: model.isArabic, timeZoneIdentifier: model.snapshot.timezoneIdentifier)))
                                .foregroundStyle(selected ? .white : WeatherPalette.muted)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)

                            Image(systemName: hour.condition.outlineSymbolName)
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(WeatherPalette.ice)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 48, height: 48)
                                .weatherGlass(
                                    in: Circle(),
                                    interactive: true,
                                    tint: selected ? WeatherPalette.ice.opacity(0.20) : WeatherPalette.deepBlue.opacity(0.20)
                                )

                            Text(WeatherFormat.temperature(hour.temperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                                .font(WeatherTypography.font(11, weight: .semibold, text: WeatherFormat.temperature(hour.temperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic)))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 56)
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(WeatherFormat.hour(hour.time, arabic: model.isArabic, timeZoneIdentifier: model.snapshot.timezoneIdentifier)), \(WeatherFormat.temperature(hour.temperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic)), \(hour.condition.localizedLabel(arabic: model.isArabic))")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var uvIndexLabel: String {
        switch model.snapshot.uvIndex {
        case ..<3: model.isArabic ? "منخفض" : "Low"
        case ..<6: model.isArabic ? "متوسط" : "Moderate"
        case ..<8: model.isArabic ? "مرتفع" : "High"
        case ..<11: model.isArabic ? "مرتفع جدًا" : "Very high"
        default: model.isArabic ? "شديد" : "Extreme"
        }
    }

    private var airQualityLabel: String {
        guard let index = model.snapshot.airQualityIndex else {
            return model.isArabic ? "غير متاح" : "Unavailable"
        }
        return switch index {
        case ...50: model.isArabic ? "جيد" : "Good"
        case ...100: model.isArabic ? "معتدل" : "Moderate"
        case ...150: model.isArabic ? "حساس" : "Sensitive"
        case ...200: model.isArabic ? "غير صحي" : "Unhealthy"
        case ...300: model.isArabic ? "غير صحي جدًا" : "Very unhealthy"
        default: model.isArabic ? "خطر" : "Hazardous"
        }
    }

    private var sampleNotice: some View {
        WeatherSourceNote(model: model)
        .padding(.horizontal, 4)
        .padding(.top, 1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

private enum HourlyChartMetric: String, CaseIterable, Identifiable, Hashable {
    case temperature
    case rainChance
    case wind

    var id: String { rawValue }

    func title(arabic: Bool) -> String {
        switch self {
        case .temperature: arabic ? "حرارة" : "Temp"
        case .rainChance: arabic ? "مطر" : "Rain"
        case .wind: arabic ? "رياح" : "Wind"
        }
    }

    var color: Color {
        switch self {
        case .temperature: WeatherPalette.amber
        case .rainChance: WeatherPalette.ice
        case .wind: WeatherPalette.mint
        }
    }

    func chartValue(for hour: HourlyForecast, fahrenheit: Bool) -> Double {
        switch self {
        case .temperature:
            fahrenheit ? hour.temperatureC * 9 / 5 + 32 : hour.temperatureC
        case .rainChance:
            Double(hour.precipitationProbability)
        case .wind:
            hour.windKPH
        }
    }

    func valueText(for hour: HourlyForecast, fahrenheit: Bool, arabic: Bool) -> String {
        switch self {
        case .temperature:
            WeatherFormat.temperature(hour.temperatureC, fahrenheit: fahrenheit, arabic: arabic)
        case .rainChance:
            "\(WeatherFormat.localizedNumber(hour.precipitationProbability, arabic: arabic))%"
        case .wind:
            "\(WeatherFormat.localizedNumber(Int(hour.windKPH.rounded()), arabic: arabic)) \(arabic ? "كم/س" : "km/h")"
        }
    }
}

private struct HourlyTrendChart: View {
    let hours: [HourlyForecast]
    let metric: HourlyChartMetric
    let selectedIndex: Int
    let fahrenheit: Bool
    let arabic: Bool
    let timeZoneIdentifier: String
    let onSelect: (Int) -> Void

    var body: some View {
        GeometryReader { geometry in
            let chartHeight = max(geometry.size.height - 20, 1)
            let values = hours.map { metric.chartValue(for: $0, fahrenheit: fahrenheit) }
            let minimumValue: Double = {
                guard let minimum = values.min() else { return 0 }
                if metric == .rainChance { return 0 }
                if metric == .wind { return 0 }
                return minimum - max(((values.max() ?? minimum) - minimum) * 0.15, 1)
            }()
            let maximumValue: Double = {
                guard let maximum = values.max() else { return 1 }
                if metric == .rainChance { return 100 }
                if metric == .wind { return max(maximum * 1.15, 10) }
                return maximum + max((maximum - (values.min() ?? maximum)) * 0.15, 1)
            }()
            let valueRange = max(maximumValue - minimumValue, 1)
            let points: [CGPoint] = values.enumerated().map { index, value in
                let progress = CGFloat(index) / CGFloat(max(values.count - 1, 1))
                return CGPoint(
                    x: geometry.size.width * (arabic ? 1 - progress : progress),
                    y: chartHeight - CGFloat((value - minimumValue) / valueRange) * chartHeight
                )
            }

            VStack(spacing: 4) {
                ZStack(alignment: .topLeading) {
                    ForEach([0.25, 0.5, 0.75], id: \.self) { fraction in
                        Path { path in
                            let y = chartHeight * fraction
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                        .stroke(.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
                    }

                    if points.count > 1 {
                        Path { path in
                            path.move(to: points[0])
                            for point in points.dropFirst() { path.addLine(to: point) }
                            path.addLine(to: CGPoint(x: points[points.count - 1].x, y: chartHeight))
                            path.addLine(to: CGPoint(x: points[0].x, y: chartHeight))
                            path.closeSubpath()
                        }
                        .fill(LinearGradient(colors: [metric.color.opacity(0.23), metric.color.opacity(0.01)], startPoint: .top, endPoint: .bottom))

                        Path { path in
                            path.move(to: points[0])
                            for point in points.dropFirst() { path.addLine(to: point) }
                        }
                        .stroke(metric.color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    }

                    if !points.isEmpty {
                        let point = points[min(max(selectedIndex, 0), points.count - 1)]
                        Path { path in
                            path.move(to: CGPoint(x: point.x, y: 0))
                            path.addLine(to: CGPoint(x: point.x, y: chartHeight))
                        }
                        .stroke(metric.color.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                        Circle()
                            .fill(metric.color)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(WeatherPalette.ink, lineWidth: 2))
                            .position(point)
                    }
                }
                .frame(height: chartHeight)
                .contentShape(Rectangle())

                if let first = hours.first, let middle = hours.dropFirst(hours.count / 2).first, let last = hours.last {
                    HStack {
                        Text(WeatherFormat.hour(first.time, arabic: arabic, timeZoneIdentifier: timeZoneIdentifier))
                        Spacer()
                        Text(WeatherFormat.hour(middle.time, arabic: arabic, timeZoneIdentifier: timeZoneIdentifier))
                        Spacer()
                        Text(WeatherFormat.hour(last.time, arabic: arabic, timeZoneIdentifier: timeZoneIdentifier))
                    }
                    .font(WeatherTypography.font(9, weight: .medium, text: WeatherFormat.hour(first.time, arabic: arabic, timeZoneIdentifier: timeZoneIdentifier)))
                    .foregroundStyle(WeatherPalette.muted)
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                guard hours.count > 1 else { return }
                let physicalProgress = min(max(value.location.x / max(geometry.size.width, 1), 0), 1)
                let logicalProgress = arabic ? 1 - physicalProgress : physicalProgress
                onSelect(Int((logicalProgress * CGFloat(hours.count - 1)).rounded()))
            })
        }
        .accessibilityElement()
        .accessibilityLabel(metric.title(arabic: arabic))
        .accessibilityValue(Text(hours.indices.contains(selectedIndex)
            ? metric.valueText(for: hours[selectedIndex], fahrenheit: fahrenheit, arabic: arabic)
            : ""))
        .accessibilityAdjustableAction { direction in
            guard !hours.isEmpty else { return }
            switch direction {
            case .increment: onSelect(min(selectedIndex + 1, hours.count - 1))
            case .decrement: onSelect(max(selectedIndex - 1, 0))
            @unknown default: break
            }
        }
    }
}

private struct LocationPickerSheet: View {
    @ObservedObject var model: WeatherViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var cityQuery = ""
    @State private var searchResults: [WeatherLocation] = []
    @State private var isSearching = false
    @State private var searchError: String?

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(model.isArabic ? "المدن المحفوظة" : "Saved cities")
                    .font(WeatherTypography.font(12, weight: .semibold, text: model.isArabic ? "المدن المحفوظة" : "Saved cities"))) {
                    ForEach(model.savedLocations) { location in
                        locationRow(location)
                    }
                }

                Section(header: Text(model.isArabic ? "إضافة مدينة" : "Add a city")
                    .font(WeatherTypography.font(12, weight: .semibold, text: model.isArabic ? "إضافة مدينة" : "Add a city"))) {
                    HStack(spacing: 9) {
                        TextField(model.isArabic ? "ابحث عن مدينة" : "Search for a city", text: $cityQuery)
                            .font(WeatherTypography.font(14, weight: .regular, text: model.isArabic ? "ابحث عن مدينة" : "Search for a city"))
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .onSubmit { Task { await searchCities() } }
                        Button {
                            Task { await searchCities() }
                        } label: {
                            if isSearching {
                                ProgressView().tint(WeatherPalette.ice)
                            } else {
                                Image(systemName: "magnifyingglass").foregroundStyle(WeatherPalette.ice)
                            }
                        }
                        .disabled(isSearching || cityQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .listRowBackground(Color.clear)

                    if let searchError {
                        Text(searchError)
                            .font(WeatherTypography.font(12, weight: .regular, text: searchError))
                            .foregroundStyle(WeatherPalette.amber)
                            .listRowBackground(Color.clear)
                    }

                    ForEach(searchResults) { location in
                        Button {
                            model.outfitFeedback = nil
                            model.addLocation(location)
                            model.chooseLocation(location)
                            dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill").foregroundStyle(WeatherPalette.mint)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(location.name)
                                        .font(WeatherTypography.font(14, weight: .medium, text: location.name))
                                        .foregroundStyle(.white)
                                    Text(location.region)
                                        .font(WeatherTypography.font(12, weight: .regular, text: location.region))
                                        .foregroundStyle(WeatherPalette.muted)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(model.isArabic ? "اختر المدينة" : "Choose a city")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(model.isArabic ? "اختر المدينة" : "Choose a city")
                        .font(WeatherTypography.font(15, weight: .semibold, text: model.isArabic ? "اختر المدينة" : "Choose a city"))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(model.isArabic ? "تم" : "Done") { dismiss() }
                        .font(WeatherTypography.font(12, weight: .semibold, text: model.isArabic ? "تم" : "Done"))
                        .foregroundStyle(WeatherPalette.ice)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func locationRow(_ location: WeatherLocation) -> some View {
        HStack(spacing: 8) {
            Button {
                model.outfitFeedback = nil
                model.chooseLocation(location)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(WeatherPalette.ice)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(location.name)
                            .font(WeatherTypography.font(14, weight: .medium, text: location.name))
                            .foregroundStyle(.white)
                        Text(location.region)
                            .font(WeatherTypography.font(12, weight: .regular, text: location.region))
                            .foregroundStyle(WeatherPalette.muted)
                    }
                    Spacer()
                    if model.snapshot.location.id == location.id {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(WeatherPalette.mint)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if model.snapshot.location.id != location.id {
                Button(role: .destructive) {
                    model.removeLocation(location)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(WeatherPalette.muted)
                        .frame(width: 34, height: 36)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(model.isArabic ? "حذف \(location.name)" : "Remove \(location.name)")
            }
        }
        .listRowBackground(Color.clear)
    }

    @MainActor
    private func searchCities() async {
        let query = cityQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = true
        searchError = nil
        defer { isSearching = false }
        do {
            searchResults = try await model.searchCities(query)
            if searchResults.isEmpty {
                searchError = model.isArabic ? "لم نعثر على نتائج. جرّب اسمًا آخر." : "No cities found. Try another name."
            }
        } catch {
            searchError = model.isArabic ? "تعذّر البحث. تحقق من الاتصال وحاول مجددًا." : "Search failed. Check your connection and try again."
        }
    }
}
