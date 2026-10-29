import SwiftUI

struct ForecastView: View {
    @ObservedObject var model: WeatherViewModel

    var body: some View {
        Group {
            if model.hasLiveData {
                ScrollView {
                    GlassEffectContainer(spacing: 0) {
                        VStack(alignment: .leading, spacing: 17) {
                            SectionHeading(
                                eyebrow: model.isArabic ? "نظرة للأمام" : "LOOK AHEAD",
                                title: model.isArabic ? "توقعات الطقس" : "Forecast"
                            )
                            summaryCard
                            GlassCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    SectionHeading(
                                        eyebrow: model.isArabic ? "الأيام السبعة القادمة" : "THE NEXT SEVEN DAYS",
                                        title: model.isArabic ? "أسبوعك" : "Your week"
                                    )
                                    HStack {
                                        Label(model.isArabic ? "احتمال المطر" : "Rain chance", systemImage: "drop.fill")
                                            .foregroundStyle(WeatherPalette.softBlue)
                                        Spacer()
                                        Text(model.isArabic ? "العظمى · الصغرى" : "High · Low")
                                            .foregroundStyle(WeatherPalette.muted)
                                    }
                                    .font(WeatherTypography.font(10, weight: .medium, text: model.isArabic ? "احتمال المطر · العظمى · الصغرى" : "Rain chance · High · Low"))
                                    VStack(spacing: 0) {
                                        ForEach(Array(model.snapshot.daily.enumerated()), id: \.element.id) { item in
                                            dailyRow(index: item.offset, day: item.element)
                                        }
                                    }
                                }
                            }
                            sampleNote
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
                .scrollIndicators(.hidden)
            } else {
                WeatherConnectionStateView(model: model)
            }
        }
    }

    private var summaryCard: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: model.snapshot.current.condition.outlineSymbolName)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(WeatherPalette.ice)
                    .font(.system(size: 27))
                    .frame(width: 43, height: 43)
                    .weatherGlass(in: RoundedRectangle(cornerRadius: 15, style: .continuous), tint: WeatherPalette.ice.opacity(0.10))
                    VStack(alignment: .leading, spacing: 4) {
                    Text(model.snapshot.location.name)
                        .font(WeatherTypography.font(14, weight: .semibold, text: model.snapshot.location.name))
                        .foregroundStyle(.white)
                    Text(model.isArabic ? "توقعات حية · Open-Meteo" : "Live forecast · Open-Meteo")
                        .font(WeatherTypography.font(10, weight: .medium, text: model.isArabic ? "توقعات حية · Open-Meteo" : "Live forecast · Open-Meteo"))
                        .foregroundStyle(WeatherPalette.muted)
                }
                Spacer(minLength: 3)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(WeatherFormat.temperature(model.snapshot.current.temperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                        .font(WeatherTypography.font(20, weight: .semibold, text: WeatherFormat.temperature(model.snapshot.current.temperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic)))
                        .foregroundStyle(.white)
                    Text(model.snapshot.current.condition.localizedLabel(arabic: model.isArabic))
                        .font(WeatherTypography.font(9, weight: .medium, text: model.snapshot.current.condition.localizedLabel(arabic: model.isArabic)))
                        .foregroundStyle(WeatherPalette.muted)
                }
            }
        }
    }

    private func dailyRow(index: Int, day: DailyForecast) -> some View {
        HStack(spacing: 10) {
            Text(dayLabel(index: index, date: day.date))
                .font(WeatherTypography.font(11, weight: .semibold, arabic: model.isArabic))
                .foregroundStyle(.white)
                .frame(width: 63, alignment: .leading)
            Image(systemName: day.condition.outlineSymbolName)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(WeatherPalette.ice)
                .font(.system(size: 18))
                .frame(width: 24)
            HStack(spacing: 3) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 8, weight: .bold))
                Text("\(WeatherFormat.localizedNumber(day.precipitationProbability, arabic: model.isArabic))%")
                    .font(WeatherTypography.font(9, weight: .semibold, text: "\(WeatherFormat.localizedNumber(day.precipitationProbability, arabic: model.isArabic))%"))
            }
            .foregroundStyle(WeatherPalette.ice)
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .weatherGlass(in: Capsule(), tint: WeatherPalette.softBlue.opacity(0.12))
            Spacer(minLength: 0)
            Text(WeatherFormat.temperature(day.highC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                .font(WeatherTypography.font(12, weight: .semibold, arabic: model.isArabic))
                .foregroundStyle(.white)
            temperatureRangeBar(for: day)
                .frame(width: 39, height: 5)
            Text(WeatherFormat.temperature(day.lowC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                .font(WeatherTypography.font(10, weight: .medium, arabic: model.isArabic))
                .foregroundStyle(WeatherPalette.muted)
        }
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
    }

    private func temperatureRangeBar(for day: DailyForecast) -> some View {
        let lows = model.snapshot.daily.map(\.lowC)
        let highs = model.snapshot.daily.map(\.highC)
        let minimum = lows.min() ?? day.lowC
        let maximum = highs.max() ?? day.highC
        let span = max(maximum - minimum, 1)
        let start = CGFloat((day.lowC - minimum) / span)
        let length = CGFloat((day.highC - day.lowC) / span)

        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.10))
                Capsule()
                    .fill(LinearGradient(colors: [WeatherPalette.ice, WeatherPalette.amber], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(5, geometry.size.width * length))
                    .offset(x: geometry.size.width * start)
            }
        }
        .accessibilityHidden(true)
    }

    private func dayLabel(index: Int, date: Date) -> String {
        if index == 0 { return model.isArabic ? "اليوم" : "Today" }
        if index == 1 { return model.isArabic ? "غدًا" : "Tomorrow" }
        return WeatherFormat.weekday(date, arabic: model.isArabic, timeZoneIdentifier: model.snapshot.timezoneIdentifier)
    }

    private var sampleNote: some View {
        WeatherSourceNote(model: model)
            .padding(.horizontal, 4)
    }
}
