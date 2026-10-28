import Foundation

/// Open-Meteo's free endpoint is for non-commercial use. Keep visible attribution in the app.
struct OpenMeteoWeatherProvider: WeatherDataProvider {
    func forecast(for location: WeatherLocation) async throws -> WeatherSnapshot {
        async let airQualityIndex = fetchAirQualityIndex(for: location)
        let response = try await fetchForecast(for: location)
        let airQuality = await airQualityIndex
        return try response.snapshot(for: location, airQualityIndex: airQuality)
    }

    private func fetchForecast(for location: WeatherLocation) async throws -> ForecastResponse {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_gusts_10m,uv_index"),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation_probability,weather_code"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh")
        ]
        guard let url = components.url else { throw OpenMeteoError.invalidURL }
        return try await get(ForecastResponse.self, from: url)
    }

    private func fetchAirQualityIndex(for location: WeatherLocation) async -> Int? {
        var components = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "current", value: "us_aqi"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = components.url else { return nil }
        do {
            let response = try await get(AirQualityResponse.self, from: url)
            guard let value = response.current.usAQI else { return nil }
            return Int(value.rounded())
        } catch {
            // Air quality is an optional extra; a failed AQI request must not hide valid weather.
            return nil
        }
    }

    private func get<Response: Decodable>(_ type: Response.Type, from url: URL) async throws -> Response {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenMeteoError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw OpenMeteoError.httpStatus(httpResponse.statusCode)
        }
        return try JSONDecoder().decode(type, from: data)
    }
}

private enum OpenMeteoError: Error {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case incompleteForecast
}

private struct ForecastResponse: Decodable {
    let timezone: String
    let current: CurrentBlock
    let hourly: HourlyBlock
    let daily: DailyBlock

    func snapshot(for location: WeatherLocation, airQualityIndex: Int?) throws -> WeatherSnapshot {
        let timeZone = TimeZone(identifier: timezone) ?? TimeZone(secondsFromGMT: 0)!
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = timeZone
        dayFormatter.dateFormat = "yyyy-MM-dd"
        guard let observedAt = dateFormatter.date(from: current.time) else {
            throw OpenMeteoError.incompleteForecast
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let firstDisplayedHour = calendar.dateInterval(of: .hour, for: observedAt)?.start ?? observedAt
        let hourlyCount = [hourly.time.count, hourly.temperature.count, hourly.precipitationProbability.count, hourly.weatherCode.count].min() ?? 0
        var hourlyForecast: [HourlyForecast] = []
        for index in 0..<hourlyCount {
            guard let time = dateFormatter.date(from: hourly.time[index]),
                  time >= firstDisplayedHour,
                  let temperature = hourly.temperature[index],
                  let precipitationChance = hourly.precipitationProbability[index],
                  let weatherCode = hourly.weatherCode[index] else { continue }
            hourlyForecast.append(HourlyForecast(
                id: hourly.time[index],
                time: time,
                temperatureC: temperature,
                condition: WeatherCondition.from(wmoCode: weatherCode),
                precipitationProbability: precipitationChance
            ))
            if hourlyForecast.count == 24 { break }
        }

        let dailyCount = [daily.time.count, daily.high.count, daily.low.count, daily.precipitationProbability.count, daily.weatherCode.count].min() ?? 0
        var dailyForecast: [DailyForecast] = []
        for index in 0..<dailyCount {
            guard let date = dayFormatter.date(from: daily.time[index]),
                  let high = daily.high[index],
                  let low = daily.low[index],
                  let precipitationChance = daily.precipitationProbability[index],
                  let weatherCode = daily.weatherCode[index] else { continue }
            dailyForecast.append(DailyForecast(
                id: daily.time[index],
                date: date,
                highC: high,
                lowC: low,
                condition: WeatherCondition.from(wmoCode: weatherCode),
                precipitationProbability: precipitationChance
            ))
        }

        guard !hourlyForecast.isEmpty, !dailyForecast.isEmpty else {
            throw OpenMeteoError.incompleteForecast
        }

        return WeatherSnapshot(
            location: location,
            timezoneIdentifier: timezone,
            observedAt: observedAt,
            current: CurrentWeather(
                temperatureC: current.temperature,
                apparentTemperatureC: current.apparentTemperature,
                condition: WeatherCondition.from(wmoCode: current.weatherCode),
                windKPH: current.windSpeed,
                precipitationMM: current.precipitation
            ),
            hourly: hourlyForecast,
            daily: dailyForecast,
            humidityPercent: current.relativeHumidity,
            uvIndex: Int(current.uvIndex.rounded()),
            windGustKPH: Int(current.windGusts.rounded()),
            airQualityIndex: airQualityIndex
        )
    }
}

private struct CurrentBlock: Decodable {
    let time: String
    let temperature: Double
    let relativeHumidity: Int
    let apparentTemperature: Double
    let precipitation: Double
    let weatherCode: Int
    let windSpeed: Double
    let windGusts: Double
    let uvIndex: Double

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case relativeHumidity = "relative_humidity_2m"
        case apparentTemperature = "apparent_temperature"
        case precipitation
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
        case windGusts = "wind_gusts_10m"
        case uvIndex = "uv_index"
    }
}

private struct HourlyBlock: Decodable {
    let time: [String]
    let temperature: [Double?]
    let precipitationProbability: [Int?]
    let weatherCode: [Int?]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case precipitationProbability = "precipitation_probability"
        case weatherCode = "weather_code"
    }
}

private struct DailyBlock: Decodable {
    let time: [String]
    let high: [Double?]
    let low: [Double?]
    let precipitationProbability: [Int?]
    let weatherCode: [Int?]

    enum CodingKeys: String, CodingKey {
        case time
        case high = "temperature_2m_max"
        case low = "temperature_2m_min"
        case precipitationProbability = "precipitation_probability_max"
        case weatherCode = "weather_code"
    }
}

private struct AirQualityResponse: Decodable {
    let current: AirQualityCurrent
}

private struct AirQualityCurrent: Decodable {
    let usAQI: Double?

    enum CodingKeys: String, CodingKey {
        case usAQI = "us_aqi"
    }
}
