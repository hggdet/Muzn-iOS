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
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    VStack(spacing: 0) {
                                        ForEach(Array(model.snapshot.daily.enumerated()), id: \.element.id) { item in
                                            dailyRow(index: item.offset, day: item.element)
                                            if item.offset < model.snapshot.daily.count - 1 {
                                                Divider().overlay(.white.opacity(0.08)).padding(.leading, 42)
                                            }
                                        }
                                    }
                                }
                            }
                            GlassCard {
                                VStack(alignment: .leading, spacing: 13) {
                                    SectionHeading(
                                        eyebrow: model.isArabic ? "الساعات القادمة" : "HOUR BY HOUR",
                                        title: model.isArabic ? "على مدار اليوم" : "The next 24 hours"
                                    )
                                    ForEach(Array(model.snapshot.hourly.enumerated()), id: \.element.id) { item in
                                        hourlyRow(hour: item.element, index: item.offset)
                                        if item.offset < model.snapshot.hourly.count - 1 {
                                            Divider().overlay(.white.opacity(0.07)).padding(.leading, 39)
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
                Image(systemName: model.snapshot.current.condition.symbolName)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(WeatherPalette.ice, WeatherPalette.amber)
                    .font(.system(size: 27))
                    .frame(width: 43, height: 43)
                    .background(WeatherPalette.ice.opacity(0.10), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.snapshot.location.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(model.isArabic ? "توقعات حية · Open-Meteo" : "Live forecast · Open-Meteo")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(WeatherPalette.muted)
                }
                Spacer(minLength: 3)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(WeatherFormat.temperature(model.snapshot.current.temperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(model.snapshot.current.condition.localizedLabel(arabic: model.isArabic))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(WeatherPalette.muted)
                }
            }
        }
    }

    private func dailyRow(index: Int, day: DailyForecast) -> some View {
        HStack(spacing: 10) {
            Text(dayLabel(index: index, date: day.date))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 76, alignment: .leading)
            Image(systemName: day.condition.symbolName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(WeatherPalette.ice, WeatherPalette.amber)
                .font(.system(size: 18))
                .frame(width: 27)
            HStack(spacing: 3) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 8, weight: .bold))
                Text("\(WeatherFormat.localizedNumber(day.precipitationProbability, arabic: model.isArabic))%")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(WeatherPalette.ice)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(WeatherPalette.softBlue.opacity(0.12), in: Capsule())
            Spacer(minLength: 2)
            Text(WeatherFormat.temperature(day.highC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(WeatherFormat.temperature(day.lowC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(WeatherPalette.muted)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private func hourlyRow(hour: HourlyForecast, index: Int) -> some View {
        HStack(spacing: 10) {
            Text(index == 0 ? (model.isArabic ? "الآن" : "Now") : WeatherFormat.hour(hour.time, arabic: model.isArabic, timeZoneIdentifier: model.snapshot.timezoneIdentifier))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 61, alignment: .leading)
            Image(systemName: hour.condition.symbolName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(WeatherPalette.ice, WeatherPalette.amber)
                .font(.system(size: 17))
                .frame(width: 25)
            Text("\(WeatherFormat.localizedNumber(hour.precipitationProbability, arabic: model.isArabic))%")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(WeatherPalette.ice)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(WeatherPalette.softBlue.opacity(0.12), in: Capsule())
            Spacer(minLength: 2)
            Text(hour.condition.localizedLabel(arabic: model.isArabic))
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(WeatherPalette.muted)
                .lineLimit(1)
            Text(WeatherFormat.temperature(hour.temperatureC, fahrenheit: model.usesFahrenheit, arabic: model.isArabic))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 42, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
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
