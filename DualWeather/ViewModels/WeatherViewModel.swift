import Foundation
import Combine
import CoreLocation
import SwiftUI

enum LocationStatus: Equatable {
    case waiting
    case loading
    case loaded
    case error(String)

    var message: String {
        switch self {
        case .waiting: return "Waiting for location..."
        case .loading: return "Fetching weather..."
        case .loaded: return ""
        case .error(let msg): return msg
        }
    }
}

class WeatherViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Published Properties

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var weatherData: WeatherResponse? = nil
    @Published var cityName: String = ""
    @Published var locationStatus: LocationStatus = .waiting
    @Published var forecastData: ForecastResponse? = nil
    @Published var isForecastLoading: Bool = false

    // MARK: - Private

    private let locationManager = CLLocationManager()
    private let weatherService = WeatherService()

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Temperature (Kelvin → F / C)

    var tempF: String {
        guard let k = weatherData?.main.temp else { return "--°F" }
        return String(format: "%.0f°F", (k - 273.15) * 9.0 / 5.0 + 32.0)
    }

    var tempC: String {
        guard let k = weatherData?.main.temp else { return "--°C" }
        return String(format: "%.0f°C", k - 273.15)
    }

    var feelsLikeF: String {
        guard let k = weatherData?.main.feelsLike else { return "--°F" }
        return String(format: "%.0f°F", (k - 273.15) * 9.0 / 5.0 + 32.0)
    }

    var feelsLikeC: String {
        guard let k = weatherData?.main.feelsLike else { return "--°C" }
        return String(format: "%.0f°C", k - 273.15)
    }

    // MARK: - Wind (m/s → mph / km/h)

    var windMph: String {
        guard let speed = weatherData?.wind.speed else { return "-- mph" }
        return String(format: "%.0f mph", speed * 2.237)
    }

    var windKmh: String {
        guard let speed = weatherData?.wind.speed else { return "-- km/h" }
        return String(format: "%.0f km/h", speed * 3.6)
    }

    var windDirection: String {
        guard let deg = weatherData?.wind.deg else { return "--" }
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((deg + 22.5).truncatingRemainder(dividingBy: 360) / 45.0)
        return directions[index % 8]
    }

    // MARK: - Visibility (meters → miles / km)

    var visibilityMiles: String {
        guard let meters = weatherData?.visibility else { return "-- mi" }
        return String(format: "%.1f mi", Double(meters) / 1609.34)
    }

    var visibilityKm: String {
        guard let meters = weatherData?.visibility else { return "-- km" }
        return String(format: "%.0f km", Double(meters) / 1000.0)
    }

    // MARK: - Pressure (hPa → inHg / hPa)

    var pressureInHg: String {
        guard let hpa = weatherData?.main.pressure else { return "-- inHg" }
        return String(format: "%.2f inHg", hpa * 0.02953)
    }

    var pressureHpa: String {
        guard let hpa = weatherData?.main.pressure else { return "-- hPa" }
        return String(format: "%.0f hPa", hpa)
    }

    // MARK: - Other

    var humidity: String {
        guard let h = weatherData?.main.humidity else { return "--%" }
        return "\(h)%"
    }

    var weatherDescription: String {
        weatherData?.weather.first?.description.capitalized ?? "--"
    }

    var weatherIconCode: String {
        weatherData?.weather.first?.icon ?? "01d"
    }

    var lastUpdated: String {
        guard let dt = weatherData?.dt else { return "" }
        let date = Date(timeIntervalSince1970: TimeInterval(dt))
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "Updated \(formatter.string(from: date))"
    }

    // MARK: - SF Symbol Mapping

    var sfSymbolName: String {
        Self.sfSymbolName(for: weatherIconCode)
    }

    var sfSymbolColor: Color {
        Self.sfSymbolColor(for: weatherIconCode)
    }

    static func sfSymbolName(for iconCode: String) -> String {
        switch iconCode {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snowflake"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }

    static func sfSymbolColor(for iconCode: String) -> Color {
        switch iconCode {
        case "01d": return .yellow
        case "01n": return .indigo
        case "02d", "02n": return .orange
        case "03d", "03n", "04d", "04n": return .gray
        case "09d", "09n", "10d", "10n": return .blue
        case "11d", "11n": return .yellow
        case "13d", "13n": return .cyan
        case "50d", "50n": return .gray
        default: return .gray
        }
    }

    // MARK: - Forecast Computed Properties

    var hourlyForecast: [ForecastItem] {
        guard let items = forecastData?.list else { return [] }
        let now = Date().timeIntervalSince1970
        return Array(items.filter { Double($0.dt) > now }.prefix(8))
    }

    var dailyForecast: [DailyForecast] {
        guard let items = forecastData?.list else { return [] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let grouped = Dictionary(grouping: items) { item -> Date in
            calendar.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(item.dt)))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"

        return grouped
            .filter { $0.key > today }
            .sorted { $0.key < $1.key }
            .prefix(5)
            .map { (day, items) in
                let noonTarget = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day)!
                let representative = items.min { a, b in
                    let aDist = abs(Double(a.dt) - noonTarget.timeIntervalSince1970)
                    let bDist = abs(Double(b.dt) - noonTarget.timeIntervalSince1970)
                    return aDist < bDist
                } ?? items[0]

                let high = items.map(\.main.temp).max() ?? representative.main.temp
                let low = items.map(\.main.temp).min() ?? representative.main.temp
                let maxPop = items.map(\.pop).max() ?? 0

                return DailyForecast(
                    date: day,
                    dayName: formatter.string(from: day),
                    high: high,
                    low: low,
                    icon: representative.weather.first?.icon ?? "01d",
                    description: representative.weather.first?.description.capitalized ?? "--",
                    pop: maxPop
                )
            }
    }

    // MARK: - Forecast Display Helpers

    func forecastTempF(_ item: ForecastItem) -> String {
        String(format: "%.0f°F", (item.main.temp - 273.15) * 9.0 / 5.0 + 32.0)
    }

    func forecastTempC(_ item: ForecastItem) -> String {
        String(format: "%.0f°C", item.main.temp - 273.15)
    }

    func forecastTime(_ item: ForecastItem) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(item.dt))
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }

    func forecastHighF(_ day: DailyForecast) -> String {
        String(format: "%.0f°F", (day.high - 273.15) * 9.0 / 5.0 + 32.0)
    }

    func forecastHighC(_ day: DailyForecast) -> String {
        String(format: "%.0f°C", day.high - 273.15)
    }

    func forecastLowF(_ day: DailyForecast) -> String {
        String(format: "%.0f°F", (day.low - 273.15) * 9.0 / 5.0 + 32.0)
    }

    func forecastLowC(_ day: DailyForecast) -> String {
        String(format: "%.0f°C", day.low - 273.15)
    }

    func forecastPop(_ item: ForecastItem) -> String? {
        guard item.pop >= 0.1 else { return nil }
        return "\(Int(item.pop * 100))%"
    }

    // MARK: - Location Methods

    func requestLocation() {
        locationStatus = .waiting
        locationManager.startUpdatingLocation()
    }

    func refreshWeather() {
        requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager.stopUpdatingLocation()
        locationStatus = .loading
        isLoading = true

        Task {
            await fetchWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationStatus = .error("Unable to determine location. Please try again.")
        errorMessage = error.localizedDescription
        isLoading = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        case .denied, .restricted:
            locationStatus = .error("Location access denied. Please enable in Settings.")
            isLoading = false
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Fetch Weather

    private func fetchWeather(lat: Double, lon: Double) async {
        do {
            let response = try await weatherService.fetchWeather(lat: lat, lon: lon)
            await MainActor.run {
                self.weatherData = response
                self.cityName = response.name
                self.locationStatus = .loaded
                self.isLoading = false
                self.errorMessage = nil
                self.isForecastLoading = true
            }

            // Fetch forecast separately — failure should not affect current weather
            do {
                let forecast = try await weatherService.fetchForecast(lat: lat, lon: lon)
                await MainActor.run {
                    self.forecastData = forecast
                    self.isForecastLoading = false
                }
            } catch {
                print("Forecast fetch failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.isForecastLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.locationStatus = .error("Failed to fetch weather data.")
                self.isLoading = false
            }
        }
    }
}
