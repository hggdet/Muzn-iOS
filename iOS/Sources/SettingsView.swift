import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: WeatherViewModel
    let onManageCities: () -> Void

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 0) {
                VStack(alignment: .leading, spacing: 17) {
                    SectionHeading(
                        eyebrow: model.isArabic ? "تفضيلاتك" : "YOUR PREFERENCES",
                        title: model.isArabic ? "الإعدادات" : "Settings"
                    )

                    citiesCard
                    temperatureCard
                    languageCard
                    WeatherSourceNote(model: model)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var citiesCard: some View {
        Button(action: onManageCities) {
            GlassCard(interactive: true) {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(WeatherPalette.ice)
                        .frame(width: 40, height: 40)
                        .background(WeatherPalette.ice.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.isArabic ? "مدن الطقس" : "Weather cities")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(model.isArabic
                             ? "إضافة مدينة أو تبديلها أو حذفها · \(WeatherFormat.localizedNumber(model.savedLocations.count, arabic: true)) محفوظة"
                             : "Add, switch or remove cities · \(model.savedLocations.count) saved")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(WeatherPalette.muted)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 2)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(model.snapshot.location.name)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(WeatherPalette.ice)
                            .lineLimit(1)
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(WeatherPalette.muted)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(model.isArabic ? "إدارة مدن الطقس" : "Manage weather cities")
    }

    private var temperatureCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 10) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(WeatherPalette.amber)
                        .frame(width: 35, height: 35)
                        .background(WeatherPalette.amber.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.isArabic ? "درجة الحرارة" : "Temperature")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(model.isArabic ? "اختر وحدة العرض" : "Choose how temperatures are shown")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(WeatherPalette.muted)
                    }
                }

                Picker(model.isArabic ? "وحدة الحرارة" : "Temperature unit", selection: $model.usesFahrenheit) {
                    Text("°C").tag(false)
                    Text("°F").tag(true)
                }
                .pickerStyle(.segmented)
                .tint(WeatherPalette.ice)
                .accessibilityLabel(model.isArabic ? "وحدة الحرارة" : "Temperature unit")
            }
        }
    }

    private var languageCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 10) {
                    Image(systemName: "character.bubble")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(WeatherPalette.mint)
                        .frame(width: 35, height: 35)
                        .background(WeatherPalette.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.isArabic ? "لغة التطبيق" : "App language")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(model.isArabic ? "العربية والإنجليزية" : "Arabic and English")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(WeatherPalette.muted)
                    }
                }

                HStack(spacing: 9) {
                    languageButton(isArabic: true, title: "العربية")
                    languageButton(isArabic: false, title: "English")
                }
            }
        }
    }

    private func languageButton(isArabic: Bool, title: String) -> some View {
        let isSelected = model.isArabic == isArabic
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { model.isArabic = isArabic }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? WeatherPalette.ink : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .weatherGlass(in: Capsule(), interactive: true, tint: isSelected ? WeatherPalette.ice : nil)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
