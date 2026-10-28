import Foundation

struct WeatherGeocodingService {
    private struct SearchResponse: Decodable {
        let results: [GeocodedCity]?
    }

    private struct GeocodedCity: Decodable {
        let id: Int?
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String?
        let admin1: String?
    }

    func search(_ query: String) async throws -> [WeatherLocation] {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let results = try JSONDecoder().decode(SearchResponse.self, from: data).results ?? []
        return results.map { result in
            let region = [result.admin1, result.country]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            return WeatherLocation(
                id: "geocoded-\(result.id ?? 0)-\(result.latitude)-\(result.longitude)",
                name: result.name,
                region: region,
                latitude: result.latitude,
                longitude: result.longitude
            )
        }
    }
}
