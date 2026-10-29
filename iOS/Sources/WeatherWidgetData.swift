import Foundation

struct WeatherWidgetData: Codable {
    let location: WeatherLocation
    let condition: WeatherCondition
    let temperatureC: Double
    let apparentTemperatureC: Double
    let windKPH: Double
    let humidityPercent: Int
    let uvIndex: Int
    let highC: Double
    let lowC: Double
    let precipitationProbability: Int
    let observedAt: Date
    var isArabic: Bool
    var usesFahrenheit: Bool
}

enum WeatherWidgetStore {
    static let appGroupIdentifier = "group.com.cue.weatherprototype.windy"
    private static let snapshotKey = "muzn.widget.snapshot"
    private static let languageKey = "muzn.widget.isArabic"
    private static let temperatureKey = "muzn.widget.usesFahrenheit"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    static func preferences() -> (isArabic: Bool, usesFahrenheit: Bool) {
        let store = defaults
        return (
            store?.object(forKey: languageKey) as? Bool ?? true,
            store?.object(forKey: temperatureKey) as? Bool ?? false
        )
    }

    static func savePreferences(isArabic: Bool, usesFahrenheit: Bool) {
        guard let store = defaults else { return }
        store.set(isArabic, forKey: languageKey)
        store.set(usesFahrenheit, forKey: temperatureKey)
        guard var data = loadRaw() else { return }
        data.isArabic = isArabic
        data.usesFahrenheit = usesFahrenheit
        saveRaw(data)
    }

    static func save(snapshot: WeatherSnapshot, isArabic: Bool, usesFahrenheit: Bool) {
        guard let today = snapshot.daily.first else { return }
        let data = WeatherWidgetData(
            location: snapshot.location,
            condition: snapshot.current.condition,
            temperatureC: snapshot.current.temperatureC,
            apparentTemperatureC: snapshot.current.apparentTemperatureC,
            windKPH: snapshot.current.windKPH,
            humidityPercent: snapshot.humidityPercent,
            uvIndex: snapshot.uvIndex,
            highC: today.highC,
            lowC: today.lowC,
            precipitationProbability: snapshot.hourly.first?.precipitationProbability ?? today.precipitationProbability,
            observedAt: snapshot.observedAt,
            isArabic: isArabic,
            usesFahrenheit: usesFahrenheit
        )
        saveRaw(data)
    }

    static func load() -> WeatherWidgetData? {
        guard var data = loadRaw() else { return nil }
        let currentPreferences = preferences()
        data.isArabic = currentPreferences.isArabic
        data.usesFahrenheit = currentPreferences.usesFahrenheit
        return data
    }

    private static func loadRaw() -> WeatherWidgetData? {
        guard let data = defaults?.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WeatherWidgetData.self, from: data)
    }

    private static func saveRaw(_ data: WeatherWidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults?.set(encoded, forKey: snapshotKey)
    }
}
