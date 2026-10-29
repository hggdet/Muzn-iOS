import Foundation

struct WeatherLocation: Identifiable, Equatable, Codable, Sendable {
    let id: String
    let name: String
    let region: String
    let latitude: Double
    let longitude: Double

    static let baghdad = WeatherLocation(
        id: "baghdad",
        name: "Baghdad",
        region: "Iraq",
        latitude: 33.3152,
        longitude: 44.3661
    )

    static let fortMcMurray = WeatherLocation(
        id: "fort-mcmurray",
        name: "Fort McMurray",
        region: "Alberta, Canada",
        latitude: 56.7268,
        longitude: -111.3790
    )
}

enum WeatherCondition: String, CaseIterable, Identifiable, Codable, Sendable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case snow
    case thunderstorm
    case fog

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .clear: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .cloudy: "cloud.fill"
        case .rain: "cloud.rain.fill"
        case .snow: "cloud.snow.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        case .fog: "cloud.fog.fill"
        }
    }

    var outlineSymbolName: String {
        switch self {
        case .clear: "sun.max"
        case .partlyCloudy: "cloud.sun"
        case .cloudy: "cloud"
        case .rain: "cloud.rain"
        case .snow: "cloud.snow"
        case .thunderstorm: "cloud.bolt.rain"
        case .fog: "cloud.fog"
        }
    }

    var labelEnglish: String {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .cloudy: "Cloudy"
        case .rain: "Rain"
        case .snow: "Snow"
        case .thunderstorm: "Thunderstorm"
        case .fog: "Fog"
        }
    }

    var labelArabic: String {
        switch self {
        case .clear: "صافٍ"
        case .partlyCloudy: "غائم جزئيًا"
        case .cloudy: "غائم"
        case .rain: "مطر"
        case .snow: "ثلج"
        case .thunderstorm: "عاصفة رعدية"
        case .fog: "ضباب"
        }
    }

    func localizedLabel(arabic: Bool) -> String {
        arabic ? labelArabic : labelEnglish
    }

    static func from(wmoCode: Int) -> WeatherCondition {
        switch wmoCode {
        case 0: .clear
        case 1, 2: .partlyCloudy
        case 3: .cloudy
        case 45, 48: .fog
        case 51...67, 80...82: .rain
        case 71...77, 85...86: .snow
        case 95...99: .thunderstorm
        default: .cloudy
        }
    }
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

struct CurrentWeather: Equatable, Sendable {
    let temperatureC: Double
    let apparentTemperatureC: Double
    let condition: WeatherCondition
    let windKPH: Double
    let precipitationMM: Double
}

struct HourlyForecast: Identifiable, Equatable, Sendable {
    let id: String
    let time: Date
    let temperatureC: Double
    let windKPH: Double
    let condition: WeatherCondition
    let precipitationProbability: Int
}

struct DailyForecast: Identifiable, Equatable, Sendable {
    let id: String
    let date: Date
    let highC: Double
    let lowC: Double
    let condition: WeatherCondition
    let precipitationProbability: Int
}

struct WeatherSnapshot: Equatable, Sendable {
    let location: WeatherLocation
    let timezoneIdentifier: String
    let observedAt: Date
    let current: CurrentWeather
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
    let humidityPercent: Int
    let uvIndex: Int
    let windGustKPH: Int
    let airQualityIndex: Int?

    static func empty(for location: WeatherLocation) -> WeatherSnapshot {
        WeatherSnapshot(
            location: location,
            timezoneIdentifier: "UTC",
            observedAt: .distantPast,
            current: CurrentWeather(
                temperatureC: 0,
                apparentTemperatureC: 0,
                condition: .cloudy,
                windKPH: 0,
                precipitationMM: 0
            ),
            hourly: [],
            daily: [],
            humidityPercent: 0,
            uvIndex: 0,
            windGustKPH: 0,
            airQualityIndex: nil
        )
    }
}
