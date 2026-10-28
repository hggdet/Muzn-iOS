import SwiftUI

struct WeatherHomeView: View {
    @ObservedObject var model: WeatherViewModel
    @State private var showingLocations = false
    @State private var selectedHourIndex = 0

    var body: some View {
        ZStack {
            WeatherBackdrop(condition: model.snapshot.current.condition)

            VStack(spacing: 0) {
                topBar
                if model.refreshFailed, model.hasLiveData {
                    Label(
                        model.isArabic ? "تعذّر التحديث؛ نعرض آخر قراءة ناجحة." : "Refresh failed; showing the last successful reading.",
                        systemImage: "wifi.exclamationmark"
                    )
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(WeatherPalette.amber)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 7)
                }
                TabView(selection: $model.selectedTab) {
                    todayPage
                        .tabItem { Label(model.isArabic ? "اليوم" : "Today", systemImage: "sun.max.fill") }
                        .tag(MainTab.today)
                    ForecastView(model: model)
                        .tabItem { Label(model.isArabic ? "التوقعات" : "Forecast", systemImage: "calendar") }
                        .tag(MainTab.forecast)
                    SettingsView(model: model, onManageCities: { showingLocations = true })
                        .tabItem { Label(model.isArabic ? "الإعدادات" : "Settings", systemImage: "gearshape.fill") }
                        .tag(MainTab.settings)
                }
                .tint(WeatherPalette.ice)
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

    private var topBar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 9) {
                HStack(spacing: 7) {
                    Image("MuznLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
                    Text("مُزن")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .fixedSize()
    
                Button { showingLocations = true } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WeatherPalette.ice)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(model.snapshot.location.name)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                            Text(model.snapshot.location.region)
                                .font(.system(size: 9, weight: .regular, design: .rounded))
                                .foregroundStyle(WeatherPalette.muted)
                                .lineLimit(1)
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(WeatherPalette.muted)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .weatherGlass(in: Capsule(), interactive: true)
                .accessibilityLabel(model.isArabic ? "اختيار المدينة" : "Choose city")
    
                Spacer(minLength: 0)
    
                Button { model.isArabic.toggle() } label: {
                    Text(model.isArabic ? "EN" : "ع" )
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 29, height: 29)
                }
                .buttonStyle(.plain)
                .weatherGlass(in: Circle(), interactive: true)
                .accessibilityLabel(model.isArabic ? "Switch to English" : "التبديل إلى العربية")
    
                Button { model.refresh() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(model.isRefreshing ? WeatherPalette.ice.opacity(0.6) : .white)
                        .frame(width: 29, height: 29)
                }
                .buttonStyle(.plain)
                .weatherGlass(in: Circle(), interactive: true)
                .disabled(model.isRefreshing)
                .accessibilityLabel(model.isArabic ? "تحديث الطقس المباشر" : "Refresh live weather")
            }
            .padding(.horizontal, 18)
            .padding(.top, 7)
            .padding(.bottom, 7)
        }
    }

    private var todayPage: some View {
        Group {
            if model.hasLiveData {
                ScrollView {
                    GlassEffectContainer(spacing: 0) {
                        VStack(alignment: .leading, spacing: 17) {
                            currentWeatherHero
                            clothingCard
                            hourlySection
                            precipitationCard
                            radarCard
                            metricsGrid
                            nextDayCard
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
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(model.isArabic ? "مسرح الجو" : "WEATHER STAGE", systemImage: "sparkles")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(WeatherPalette.ice)
                    Spacer()
                    HStack(spacing: 5) {
                        Circle().fill(WeatherPalette.mint).frame(width: 5, height: 5)
                        Text(model.isArabic ? "مباشر" : "LIVE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .weatherGlass(in: Capsule())
                }

                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.snapshot.location.name)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(WeatherPalette.muted)
                            .lineLimit(1)
                        Text(WeatherFormat.temperature(model.snapshot.current.temperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                            .font(.system(size: 76, weight: .light, design: .rounded))
                            .tracking(-5)
                            .contentTransition(.numericText())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                        Text(model.snapshot.current.condition.localizedLabel(arabic: model.isArabic))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    Spacer(minLength: 0)
                    WeatherStageOrb(condition: model.snapshot.current.condition)
                        .frame(width: 112, height: 116)
                }

                HStack(spacing: 7) {
                    heroMetric(
                        symbol: "thermometer.medium",
                        title: model.isArabic ? "المحسوسة" : "FEELS LIKE",
                        value: WeatherFormat.temperature(model.snapshot.current.apparentTemperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic)
                    )
                    heroMetric(
                        symbol: "wind",
                        title: model.isArabic ? "الرياح" : "WIND",
                        value: "\(WeatherFormat.localizedNumber(Int(model.snapshot.current.windKPH.rounded()), arabic: model.isArabic)) \(model.isArabic ? "كم/س" : "km/h")"
                    )
                    heroMetric(
                        symbol: "humidity.fill",
                        title: model.isArabic ? "الرطوبة" : "HUMIDITY",
                        value: "\(WeatherFormat.localizedNumber(model.snapshot.humidityPercent, arabic: model.isArabic))%"
                    )
                }

                HStack {
                    Text(model.isArabic ? "وحدة الحرارة" : "TEMPERATURE UNIT")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.7)
                        .foregroundStyle(WeatherPalette.muted)
                    Spacer()
                    Button { model.usesFahrenheit.toggle() } label: {
                        Label(model.usesFahrenheit ? "°F" : "°C", systemImage: "thermometer.medium")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)
                    .weatherGlass(in: Capsule(), interactive: true, tint: WeatherPalette.ice.opacity(0.08))
                    .accessibilityLabel(model.isArabic ? "تغيير وحدة الحرارة" : "Change temperature unit")
                }
            }
        }
    }

    private func heroMetric(symbol: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: symbol)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(0.25)
                .foregroundStyle(WeatherPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 9)
        .weatherGlass(in: RoundedRectangle(cornerRadius: 15, style: .continuous), tint: WeatherPalette.ice.opacity(0.055))
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

    private var clothingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 11) {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(WeatherPalette.ice)
                        .frame(width: 39, height: 39)
                        .background(WeatherPalette.ice.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.isArabic ? "اقتراح شخصي" : "MADE FOR YOUR DAY")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(WeatherPalette.muted)
                        Text(outfitCardTitle)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer(minLength: 0)
                }

                Text(outfitSuggestion)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.84))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Rectangle().fill(.white.opacity(0.10)).frame(height: 1)

                HStack(spacing: 7) {
                    Text(model.isArabic ? "هل يناسبك؟" : "Is this about right?")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(WeatherPalette.muted)
                    Spacer(minLength: 0)
                    feedbackButton(.warmer, title: model.isArabic ? "أدفأ" : "Warmer", symbol: "plus")
                    feedbackButton(.lighter, title: model.isArabic ? "أخف" : "Lighter", symbol: "minus")
                }
            }
        }
    }

    private func feedbackButton(_ feedback: OutfitFeedback, title: String, symbol: String) -> some View {
        let selected = model.outfitFeedback == feedback
        return Button { withAnimation(.easeInOut(duration: 0.18)) { model.outfitFeedback = feedback } } label: {
            Label(title, systemImage: symbol)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(selected ? WeatherPalette.ink : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
            .weatherGlass(in: Capsule(), interactive: true, tint: selected ? WeatherPalette.ice : nil)
    }

    @ViewBuilder
    private var hourlySection: some View {
        let hours = Array(model.snapshot.hourly.prefix(12))
        if !hours.isEmpty {
            let index = min(max(selectedHourIndex, 0), hours.count - 1)
            let selected = hours[index]
            GlassCard {
                VStack(alignment: .leading, spacing: 13) {
                    SectionHeading(
                        eyebrow: model.isArabic ? "نافذة اليوم" : "YOUR WEATHER WINDOW",
                        title: model.isArabic ? "اختر ساعة من يومك" : "Move through the day",
                        trailing: model.isArabic ? "اسحب" : "DRAG"
                    )

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(index == 0 ? (model.isArabic ? "الآن" : "Now") : WeatherFormat.hour(selected.time, arabic: model.isArabic, timeZoneIdentifier: model.snapshot.timezoneIdentifier))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(WeatherPalette.ice)
                            Text(selected.condition.localizedLabel(arabic: model.isArabic))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Spacer(minLength: 3)
                        Image(systemName: selected.condition.symbolName)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(WeatherPalette.ice, WeatherPalette.amber)
                            .font(.system(size: 24))
                        Text(WeatherFormat.temperature(selected.temperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                            .font(.system(size: 29, weight: .light, design: .rounded))
                            .contentTransition(.numericText())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
                    .weatherGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous), tint: WeatherPalette.ice.opacity(0.06))

                    hourlyRail(hours: hours, selectedIndex: index)

                    HStack(spacing: 7) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(WeatherFormat.localizedNumber(selected.precipitationProbability, arabic: model.isArabic))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Text(model.isArabic ? "احتمال المطر" : "rain chance")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                        Spacer(minLength: 0)
                        Text(hourlyTip(for: selected))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(WeatherPalette.muted)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                            .frame(maxWidth: 190, alignment: .trailing)
                    }
                    .foregroundStyle(WeatherPalette.softBlue)
                    .padding(.top, 1)
                }
            }
        }
    }

    private func hourlyRail(hours: [HourlyForecast], selectedIndex: Int) -> some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let logicalProgress = CGFloat(selectedIndex) / CGFloat(max(hours.count - 1, 1))
                let progress = model.isArabic ? 1 - logicalProgress : logicalProgress
                ZStack(alignment: model.isArabic ? .trailing : .leading) {
                    Capsule().fill(.white.opacity(0.12)).frame(height: 3)
                    Capsule()
                        .fill(LinearGradient(colors: [WeatherPalette.ice.opacity(0.45), WeatherPalette.ice], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, geometry.size.width * progress), height: 3)
                    HStack(spacing: 0) {
                        ForEach(Array(hours.enumerated()), id: \.element.id) { index, _ in
                            Circle()
                                .fill(index == selectedIndex ? .white : WeatherPalette.ice.opacity(index == 0 ? 0.75 : 0.34))
                                .frame(width: index == selectedIndex ? 12 : 5, height: index == selectedIndex ? 12 : 5)
                                .shadow(color: index == selectedIndex ? WeatherPalette.ice.opacity(0.65) : .clear, radius: 7)
                            if index < hours.count - 1 { Spacer(minLength: 0) }
                        }
                    }
                    .frame(height: 28)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    let physicalProgress = min(max(value.location.x / max(geometry.size.width, 1), 0), 1)
                    let logicalProgress = model.isArabic ? 1 - physicalProgress : physicalProgress
                    let nextIndex = Int((logicalProgress * CGFloat(hours.count - 1)).rounded())
                    if nextIndex != selectedHourIndex {
                        withAnimation(.snappy(duration: 0.13)) { selectedHourIndex = nextIndex }
                    }
                })
            }
            .frame(height: 28)
            .accessibilityElement()
            .accessibilityLabel(model.isArabic ? "اختيار ساعة من التوقعات" : "Choose a forecast hour")
            .accessibilityValue(WeatherFormat.hour(hours[selectedIndex].time, arabic: model.isArabic, timeZoneIdentifier: model.snapshot.timezoneIdentifier))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: selectedHourIndex = min(selectedIndex + 1, hours.count - 1)
                case .decrement: selectedHourIndex = max(selectedIndex - 1, 0)
                @unknown default: break
                }
            }

            HStack {
                Text(model.isArabic ? "الآن" : "Now")
                Spacer()
                Text(WeatherFormat.hour(hours.last!.time, arabic: model.isArabic, timeZoneIdentifier: model.snapshot.timezoneIdentifier))
            }
            .font(.system(size: 9, weight: .medium, design: .rounded))
            .foregroundStyle(WeatherPalette.muted)
        }
    }

    private func hourlyTip(for hour: HourlyForecast) -> String {
        if hour.precipitationProbability >= 55 {
            return model.isArabic ? "احتمال مطر مرتفع؛ خذ مظلة." : "Rain is likely; bring an umbrella."
        }
        if hour.condition == .rain || hour.condition == .thunderstorm {
            return model.isArabic ? "قد تبتل الطرق؛ خطط لخروجك." : "Wet conditions; plan your route."
        }
        if hour.condition == .snow {
            return model.isArabic ? "انتبه من الأسطح الزلقة." : "Watch for slippery surfaces."
        }
        if hour.temperatureC >= 32 {
            return model.isArabic ? "حرارة مرتفعة؛ ابقَ رطبًا." : "High heat; keep water close."
        }
        if hour.temperatureC <= 7 {
            return model.isArabic ? "الجو بارد؛ أضف طبقة دافئة." : "Chilly; add a warm layer."
        }
        if hour.condition == .clear {
            return model.isArabic ? "سماء صافية؛ نظارة شمسية قد تفيد." : "Clear skies; sunglasses may help."
        }
        return model.isArabic ? "طقس معتدل؛ طبقة خفيفة خيار مرن." : "Mild conditions; a light layer is flexible."
    }

    private var precipitationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeading(
                    eyebrow: model.isArabic ? "فرصة الهطول" : "PRECIPITATION CHANCE",
                    title: model.isArabic ? "احتمال الهطول" : "Precipitation ahead",
                    trailing: "\(WeatherFormat.localizedNumber(model.snapshot.hourly.prefix(12).map(\.precipitationProbability).max() ?? 0, arabic: model.isArabic))%"
                )
                Text(model.isArabic ? "احتمال الهطول المتوقع للساعات القادمة" : "Forecast precipitation chance over the coming hours")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(WeatherPalette.muted)
                PrecipitationChart(hourly: Array(model.snapshot.hourly.prefix(12)))
                    .frame(height: 100)
                    .padding(.top, 2)
                HStack {
                    ForEach([0, 3, 6, 9], id: \.self) { index in
                        Text(index == 0 ? (model.isArabic ? "الآن" : "Now") : "\(index)h")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(WeatherPalette.muted.opacity(0.8))
                        if index != 9 { Spacer() }
                    }
                }
            }
        }
    }

    private var radarCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .bottom) {
                    SectionHeading(
                        eyebrow: model.isArabic ? "صورة محلية" : "LOCAL VIEW",
                        title: model.isArabic ? "مشهد الطقس" : "Weather map"
                    )
                    Spacer()
                    Label(model.isArabic ? "توضيحي" : "Illustrative", systemImage: "info.circle")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(WeatherPalette.muted)
                }
                RadarIllustration(city: model.snapshot.location.name)
                    .frame(height: 148)
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                Text(model.isArabic ? "هذه رسمة توضيحية وليست رادارًا مباشرًا." : "Illustration only — this is not live radar imagery.")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(WeatherPalette.muted)
            }
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            MetricTile(
                symbol: "sun.max.fill",
                title: model.isArabic ? "الأشعة فوق البنفسجية" : "UV INDEX",
                value: WeatherFormat.localizedNumber(model.snapshot.uvIndex, arabic: model.isArabic),
                detail: uvIndexLabel,
                tint: WeatherPalette.amber
            )
            MetricTile(
                symbol: "humidity.fill",
                title: model.isArabic ? "الرطوبة" : "HUMIDITY",
                value: WeatherFormat.localizedNumber(model.snapshot.humidityPercent, arabic: model.isArabic),
                detail: "%",
                tint: WeatherPalette.ice
            )
            MetricTile(
                symbol: "wind",
                title: model.isArabic ? "هبات الرياح" : "WIND GUSTS",
                value: WeatherFormat.localizedNumber(model.snapshot.windGustKPH, arabic: model.isArabic),
                detail: model.isArabic ? "كم/س" : "km/h",
                tint: WeatherPalette.softBlue
            )
            MetricTile(
                symbol: "aqi.medium",
                title: model.isArabic ? "جودة الهواء" : "AIR QUALITY",
                value: model.snapshot.airQualityIndex.map { WeatherFormat.localizedNumber($0, arabic: model.isArabic) } ?? "—",
                detail: airQualityLabel,
                tint: WeatherPalette.mint
            )
        }
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
        switch index {
        case ...50: model.isArabic ? "جيد" : "Good"
        case ...100: model.isArabic ? "معتدل" : "Moderate"
        case ...150: model.isArabic ? "حساس" : "Sensitive"
        case ...200: model.isArabic ? "غير صحي" : "Unhealthy"
        case ...300: model.isArabic ? "غير صحي جدًا" : "Very unhealthy"
        default: model.isArabic ? "خطر" : "Hazardous"
        }
    }

    private var nextDayCard: some View {
        let next = model.snapshot.daily.dropFirst().first ?? model.snapshot.daily.first
        return GlassCard {
            HStack(spacing: 13) {
                if let next {
                    Image(systemName: next.condition.symbolName)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(WeatherPalette.ice, WeatherPalette.amber)
                        .font(.system(size: 26))
                        .frame(width: 42)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.isArabic ? "لمحة عن الغد" : "A QUICK LOOK")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(1.3)
                            .foregroundStyle(WeatherPalette.muted)
                        Text(model.isArabic ? "غدًا باختصار" : "Tomorrow, in a nutshell")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(next.condition.localizedLabel(arabic: model.isArabic))
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(WeatherPalette.muted)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(WeatherFormat.temperature(next.highC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Text(WeatherFormat.temperature(next.lowC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(WeatherPalette.muted)
                    }
                }
            }
        }
    }

    private var sampleNotice: some View {
        WeatherSourceNote(model: model)
        .padding(.horizontal, 4)
        .padding(.top, 1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

private struct MetricTile: View {
    let symbol: String
    let title: String
    let value: String
    let detail: String
    let tint: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 7) {
                    Image(systemName: symbol).foregroundStyle(tint)
                    Text(title)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(WeatherPalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value).font(.system(size: 23, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                    Text(detail).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(WeatherPalette.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct PrecipitationChart: View {
    let hourly: [HourlyForecast]

    var body: some View {
        GeometryReader { geometry in
            let values = hourly.map { Double($0.precipitationProbability) }
            let maximum = max(values.max() ?? 1, 1)
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                Path { path in
                    for fraction in [0.25, 0.5, 0.75] {
                        let y = height * fraction
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))

                if values.count > 1 {
                    Path { path in
                        for (index, value) in values.enumerated() {
                            let point = CGPoint(x: width * CGFloat(index) / CGFloat(values.count - 1), y: height - (CGFloat(value / maximum) * height * 0.83) - 5)
                            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                        }
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.addLine(to: CGPoint(x: 0, y: height))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [WeatherPalette.ice.opacity(0.26), WeatherPalette.ice.opacity(0.01)], startPoint: .top, endPoint: .bottom))

                    Path { path in
                        for (index, value) in values.enumerated() {
                            let point = CGPoint(x: width * CGFloat(index) / CGFloat(values.count - 1), y: height - (CGFloat(value / maximum) * height * 0.83) - 5)
                            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                        }
                    }
                    .stroke(WeatherPalette.ice, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
}

private struct RadarIllustration: View {
    let city: String

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [Color(red: 0.13, green: 0.22, blue: 0.35), Color(red: 0.08, green: 0.15, blue: 0.27)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Canvas { context, size in
                    var grid = Path()
                    stride(from: 0.0, through: size.width, by: 44).forEach { x in
                        grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    stride(from: 0.0, through: size.height, by: 36).forEach { y in
                        grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(grid, with: .color(.white.opacity(0.08)), lineWidth: 0.7)

                    var road = Path()
                    road.move(to: CGPoint(x: -10, y: size.height * 0.78))
                    road.addCurve(to: CGPoint(x: size.width + 10, y: size.height * 0.30), control1: CGPoint(x: size.width * 0.28, y: size.height * 0.18), control2: CGPoint(x: size.width * 0.63, y: size.height * 0.88))
                    context.stroke(road, with: .color(WeatherPalette.ice.opacity(0.18)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                Ellipse()
                    .fill(RadialGradient(colors: [WeatherPalette.ice.opacity(0.28), WeatherPalette.softBlue.opacity(0.12), .clear], center: .center, startRadius: 8, endRadius: 92))
                    .frame(width: 220, height: 110)
                    .rotationEffect(.degrees(-18))
                    .offset(x: geometry.size.width * 0.18, y: -4)
                Circle().fill(.white).frame(width: 8, height: 8).overlay(Circle().stroke(WeatherPalette.ice.opacity(0.6), lineWidth: 4).frame(width: 18, height: 18))
                    .position(x: geometry.size.width * 0.50, y: geometry.size.height * 0.51)
                Text(city.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.white)
                    .position(x: geometry.size.width * 0.50, y: geometry.size.height * 0.67)
                Text("N")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(WeatherPalette.muted)
                    .position(x: 16, y: 15)
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
                Section(header: Text(model.isArabic ? "المدن المحفوظة" : "Saved cities")) {
                    ForEach(model.savedLocations) { location in
                        locationRow(location)
                    }
                }

                Section(header: Text(model.isArabic ? "إضافة مدينة" : "Add a city")) {
                    HStack(spacing: 9) {
                        TextField(model.isArabic ? "ابحث عن مدينة" : "Search for a city", text: $cityQuery)
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
                    .listRowBackground(WeatherPalette.card.opacity(0.65))

                    if let searchError {
                        Text(searchError)
                            .font(.system(size: 12))
                            .foregroundStyle(WeatherPalette.amber)
                            .listRowBackground(WeatherPalette.card.opacity(0.65))
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
                                    Text(location.name).foregroundStyle(.white)
                                    Text(location.region).font(.system(size: 12)).foregroundStyle(WeatherPalette.muted)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(WeatherPalette.card.opacity(0.65))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(WeatherPalette.ink)
            .navigationTitle(model.isArabic ? "اختر المدينة" : "Choose a city")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(model.isArabic ? "تم" : "Done") { dismiss() }
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
                        Text(location.name).foregroundStyle(.white)
                        Text(location.region).font(.system(size: 12)).foregroundStyle(WeatherPalette.muted)
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
        .listRowBackground(WeatherPalette.card.opacity(0.65))
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

extension WeatherCondition {
    func localizedLabel(arabic: Bool) -> String {
        arabic ? labelArabic : labelEnglish
    }
}
