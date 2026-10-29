import SwiftUI
import WidgetKit

@main
struct WindyWeatherApp: App {
    @StateObject private var model: WeatherViewModel

    init() {
        ArabicFontStore.registerBundledFont()
        ArabicFontStore.registerSavedFont()
        _model = StateObject(wrappedValue: WeatherViewModel())
    }

    var body: some Scene {
        WindowGroup {
            WeatherHomeView(model: model)
                .preferredColorScheme(.dark)
        }
    }
}

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published private(set) var snapshot: WeatherSnapshot
    @Published private(set) var hasLiveData = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var refreshFailed = false
    @Published private(set) var lastUpdatedAt: Date?
    @Published private(set) var savedLocations: [WeatherLocation]
    @Published var selectedTab: MainTab = .today
    @Published var isArabic: Bool {
        didSet {
            UserDefaults.standard.set(isArabic, forKey: Self.isArabicKey)
            WeatherWidgetStore.savePreferences(isArabic: isArabic, usesFahrenheit: usesFahrenheit)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    @Published var usesFahrenheit: Bool {
        didSet {
            UserDefaults.standard.set(usesFahrenheit, forKey: Self.usesFahrenheitKey)
            WeatherWidgetStore.savePreferences(isArabic: isArabic, usesFahrenheit: usesFahrenheit)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    @Published var arabicFontName: String {
        didSet { UserDefaults.standard.set(arabicFontName, forKey: Self.arabicFontNameKey) }
    }
    @Published private(set) var importedArabicFontName: String?
    @Published private(set) var importedArabicFontTitle: String?
    @Published var outfitFeedback: OutfitFeedback?

    private let provider: any WeatherDataProvider
    private let geocodingService = WeatherGeocodingService()
    private var refreshTask: Task<Void, Never>?
    private var requestGeneration = 0
    private static let savedLocationsKey = "savedWeatherLocations"
    private static let isArabicKey = "muzn.settings.isArabic"
    private static let usesFahrenheitKey = "muzn.settings.usesFahrenheit"
    private static let arabicFontNameKey = "muzn.settings.arabicFontName"
    private static let importedArabicFontNameKey = "muzn.settings.importedArabicFontName"
    private static let importedArabicFontTitleKey = "muzn.settings.importedArabicFontTitle"

    init(provider: any WeatherDataProvider = OpenMeteoWeatherProvider()) {
        self.provider = provider
        self.isArabic = UserDefaults.standard.object(forKey: Self.isArabicKey) as? Bool ?? true
        self.usesFahrenheit = UserDefaults.standard.object(forKey: Self.usesFahrenheitKey) as? Bool ?? false
        self.arabicFontName = UserDefaults.standard.string(forKey: Self.arabicFontNameKey) ?? "system"
        self.importedArabicFontName = UserDefaults.standard.string(forKey: Self.importedArabicFontNameKey)
        self.importedArabicFontTitle = UserDefaults.standard.string(forKey: Self.importedArabicFontTitleKey)
        let restoredLocations = UserDefaults.standard.data(forKey: Self.savedLocationsKey)
            .flatMap { try? JSONDecoder().decode([WeatherLocation].self, from: $0) } ?? []
        self.savedLocations = restoredLocations.isEmpty ? [.baghdad, .fortMcMurray] : restoredLocations
        self.snapshot = .empty(for: .baghdad)
        WeatherWidgetStore.savePreferences(isArabic: self.isArabic, usesFahrenheit: self.usesFahrenheit)
    }

    func importArabicFont(from url: URL) throws {
        let font = try ArabicFontStore.importFont(from: url)
        importedArabicFontName = font.postScriptName
        importedArabicFontTitle = font.displayName
        UserDefaults.standard.set(font.postScriptName, forKey: Self.importedArabicFontNameKey)
        UserDefaults.standard.set(font.displayName, forKey: Self.importedArabicFontTitleKey)
        arabicFontName = font.postScriptName
    }

    func selectArabicFont(_ name: String) {
        arabicFontName = name
    }

    func chooseLocation(_ location: WeatherLocation) {
        if !savedLocations.contains(where: { $0.id == location.id }) {
            addLocation(location)
        }
        guard snapshot.location.id != location.id else { return }
        snapshot = .empty(for: location)
        hasLiveData = false
        lastUpdatedAt = nil
        refreshFailed = false
        startRefresh(for: location)
    }

    func searchCities(_ query: String) async throws -> [WeatherLocation] {
        try await geocodingService.search(query)
    }

    func addLocation(_ location: WeatherLocation) {
        guard !savedLocations.contains(where: { $0.id == location.id }) else { return }
        savedLocations.append(location)
        persistLocations()
    }

    func removeLocation(_ location: WeatherLocation) {
        guard location.id != snapshot.location.id, savedLocations.count > 1 else { return }
        savedLocations.removeAll { $0.id == location.id }
        persistLocations()
    }

    private func persistLocations() {
        guard let data = try? JSONEncoder().encode(savedLocations) else { return }
        UserDefaults.standard.set(data, forKey: Self.savedLocationsKey)
    }

    func refresh() {
        guard !isRefreshing else { return }
        startRefresh(for: snapshot.location)
    }

    private func startRefresh(for location: WeatherLocation) {
        refreshTask?.cancel()
        requestGeneration += 1
        let generation = requestGeneration
        let provider = self.provider
        isRefreshing = true
        refreshFailed = false

        refreshTask = Task {
            do {
                let freshSnapshot = try await provider.forecast(for: location)
                guard !Task.isCancelled, requestGeneration == generation else { return }
                snapshot = freshSnapshot
                hasLiveData = true
                lastUpdatedAt = freshSnapshot.observedAt
                WeatherWidgetStore.save(snapshot: freshSnapshot, isArabic: isArabic, usesFahrenheit: usesFahrenheit)
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                guard !Task.isCancelled, requestGeneration == generation else { return }
                // Keep a previously successful snapshot visible if a refresh fails.
                refreshFailed = true
            }

            guard requestGeneration == generation else { return }
            isRefreshing = false
            refreshTask = nil
        }
    }
}

enum MainTab: CaseIterable, Hashable {
    case today
    case forecast
    case settings
}

enum OutfitFeedback {
    case warmer
    case lighter
}
