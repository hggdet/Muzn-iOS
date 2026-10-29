import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var model: WeatherViewModel
    let onManageCities: () -> Void
    @State private var showingFontImporter = false
    @State private var fontImportError: String?

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 0) {
                VStack(alignment: .leading, spacing: 17) {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionHeading(
                            eyebrow: model.isArabic ? "تخصيص مُزن" : "PERSONALIZE MUZN",
                            title: model.isArabic ? "الإعدادات" : "Settings"
                        )
                        Text(model.isArabic
                             ? "اضبط المدينة والوحدات واللغة بالطريقة التي تريحك."
                             : "Make the forecast feel right for you.")
                            .font(WeatherTypography.font(12, weight: .regular, arabic: model.isArabic))
                            .foregroundStyle(WeatherPalette.muted)
                    }

                    citiesCard
                    temperatureCard
                    languageCard
                    arabicFontCard

                    GlassCard {
                        HStack(spacing: 11) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(WeatherPalette.ice)
                                .frame(width: 38, height: 38)
                                .weatherGlass(in: RoundedRectangle(cornerRadius: 13, style: .continuous), tint: WeatherPalette.ice.opacity(0.12))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(model.isArabic ? "معلومات الطقس" : "Weather data")
                                    .font(WeatherTypography.font(13, weight: .semibold, arabic: model.isArabic))
                                    .foregroundStyle(.white)
                                Text(model.isArabic ? "المصدر والتحديث الأخير" : "Provider and latest refresh")
                                    .font(WeatherTypography.font(10, weight: .regular, arabic: model.isArabic))
                                    .foregroundStyle(WeatherPalette.muted)
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    WeatherSourceNote(model: model)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
        .fileImporter(isPresented: $showingFontImporter, allowedContentTypes: [.font]) { result in
            do {
                try model.importArabicFont(from: result.get())
                fontImportError = nil
            } catch {
                fontImportError = error.localizedDescription
            }
        }
    }

    private var citiesCard: some View {
        Button(action: onManageCities) {
            GlassCard(interactive: true) {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(WeatherPalette.ice)
                        .frame(width: 42, height: 42)
                        .weatherGlass(in: RoundedRectangle(cornerRadius: 15, style: .continuous), tint: WeatherPalette.ice.opacity(0.13))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.isArabic ? "مدينة الطقس" : "Weather location")
                            .font(WeatherTypography.font(14, weight: .semibold, arabic: model.isArabic))
                            .foregroundStyle(.white)
                        Text(model.isArabic
                             ? "\(WeatherFormat.localizedNumber(model.savedLocations.count, arabic: true)) مدن محفوظة"
                             : "\(model.savedLocations.count) saved cities")
                            .font(WeatherTypography.font(10, weight: .regular, arabic: model.isArabic))
                            .foregroundStyle(WeatherPalette.muted)
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(model.snapshot.location.name)
                            .font(WeatherTypography.font(11, weight: .semibold, arabic: model.isArabic))
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
                preferenceHeading(
                    symbol: "thermometer.medium",
                    title: model.isArabic ? "وحدة الحرارة" : "Temperature unit",
                    detail: model.isArabic ? "اختر ما تفضله للتوقعات" : "Choose how temperatures appear",
                    tint: WeatherPalette.amber
                )

                HStack(spacing: 9) {
                    optionButton(
                        title: "°C",
                        subtitle: model.isArabic ? "مئوية" : "Celsius",
                        symbol: "thermometer.low",
                        selected: !model.usesFahrenheit
                    ) { model.usesFahrenheit = false }
                    optionButton(
                        title: "°F",
                        subtitle: model.isArabic ? "فهرنهايت" : "Fahrenheit",
                        symbol: "thermometer.high",
                        selected: model.usesFahrenheit
                    ) { model.usesFahrenheit = true }
                }
            }
        }
    }

    private var languageCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 13) {
                preferenceHeading(
                    symbol: "character.bubble",
                    title: model.isArabic ? "لغة التطبيق" : "App language",
                    detail: model.isArabic ? "العربية والإنجليزية" : "Arabic and English",
                    tint: WeatherPalette.mint
                )

                HStack(spacing: 9) {
                    optionButton(
                        title: "العربية",
                        subtitle: model.isArabic ? "مفعّلة" : "Arabic",
                        symbol: "character",
                        selected: model.isArabic
                    ) { setLanguage(isArabic: true) }
                    optionButton(
                        title: "English",
                        subtitle: model.isArabic ? "الإنجليزية" : "Active",
                        symbol: "textformat.abc",
                        selected: !model.isArabic
                    ) { setLanguage(isArabic: false) }
                }
            }
        }
    }

    private var arabicFontCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                preferenceHeading(
                    symbol: "textformat",
                    title: model.isArabic ? "الخط العربي" : "Arabic font",
                    detail: model.isArabic
                        ? "يتغير به النص العربي داخل التطبيق؛ الودجت يستخدم خط النظام"
                        : "Changes Arabic app text; widgets use the system font",
                    tint: WeatherPalette.ice
                )

                VStack(spacing: 8) {
                    fontOption(
                        title: model.isArabic ? "خط النظام" : "System font",
                        subtitle: model.isArabic ? "الخط الافتراضي في iOS" : "Native iOS typography",
                        name: "system"
                    )
                    fontOption(
                        title: "Noto Sans Arabic",
                        subtitle: model.isArabic ? "الخط المرفق مع مُزن" : "Bundled with Muzn",
                        name: "NotoSansArabic-Regular"
                    )
                    if let importedName = model.importedArabicFontName {
                        fontOption(
                            title: model.importedArabicFontTitle ?? importedName,
                            subtitle: model.isArabic ? "خط مستورد" : "Imported font",
                            name: importedName
                        )
                    }
                }

                Button { showingFontImporter = true } label: {
                    Label(
                        model.isArabic ? "استيراد خط TTF أو OTF" : "Import a TTF or OTF font",
                        systemImage: "square.and.arrow.down"
                    )
                    .font(WeatherTypography.font(11, weight: .semibold, arabic: model.isArabic))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                }
                .buttonStyle(.plain)
                .weatherGlass(in: Capsule(), interactive: true)

                Text(model.isArabic
                     ? "استورد فقط الخطوط التي تملك حق استخدامها."
                     : "Import only fonts you have permission to use.")
                    .font(WeatherTypography.font(9, weight: .regular, text: model.isArabic
                        ? "استورد فقط الخطوط التي تملك حق استخدامها."
                        : "Import only fonts you have permission to use."))
                    .foregroundStyle(WeatherPalette.muted)

                if let fontImportError {
                    Text(fontImportError)
                        .font(WeatherTypography.font(10, weight: .medium, text: fontImportError))
                        .foregroundStyle(WeatherPalette.amber)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func fontOption(title: String, subtitle: String, name: String) -> some View {
        let selected = model.arabicFontName == name
        return Button { model.selectArabicFont(name) } label: {
            HStack(spacing: 10) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15, weight: .medium))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(WeatherTypography.font(12, weight: .semibold, text: title))
                    Text(subtitle)
                        .font(WeatherTypography.font(9, weight: .regular, text: subtitle))
                        .foregroundStyle(selected ? WeatherPalette.ink.opacity(0.72) : WeatherPalette.muted)
                }
                Spacer(minLength: 0)
                Text("مُزن")
                    .font(WeatherTypography.font(13, weight: .medium, arabic: true))
            }
            .foregroundStyle(selected ? WeatherPalette.ink : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .weatherGlass(
                in: RoundedRectangle(cornerRadius: 16, style: .continuous),
                interactive: true,
                tint: selected ? WeatherPalette.ice : nil
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func preferenceHeading(symbol: String, title: String, detail: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 37, height: 37)
                .weatherGlass(in: RoundedRectangle(cornerRadius: 13, style: .continuous), tint: tint.opacity(0.13))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(WeatherTypography.font(13, weight: .semibold, text: title))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(WeatherTypography.font(10, weight: .regular, text: detail))
                    .foregroundStyle(WeatherPalette.muted)
            }
        }
    }

    private func optionButton(
        title: String,
        subtitle: String,
        symbol: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(selected ? WeatherPalette.ink : WeatherPalette.ice)
                Text(title)
                    .font(WeatherTypography.font(12, weight: .semibold, text: title))
                    .foregroundStyle(selected ? WeatherPalette.ink : .white)
                Text(subtitle)
                    .font(WeatherTypography.font(9, weight: .regular, text: subtitle))
                    .foregroundStyle(selected ? WeatherPalette.ink.opacity(0.72) : WeatherPalette.muted)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 76)
            .weatherGlass(
                in: RoundedRectangle(cornerRadius: 18, style: .continuous),
                interactive: true,
                tint: selected ? WeatherPalette.ice : WeatherPalette.deepBlue.opacity(0.17)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func setLanguage(isArabic: Bool) {
        withAnimation(.easeInOut(duration: 0.18)) { model.isArabic = isArabic }
    }
}
