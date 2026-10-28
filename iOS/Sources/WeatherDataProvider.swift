import Foundation

protocol WeatherDataProvider {
    func forecast(for location: WeatherLocation) async throws -> WeatherSnapshot
}
