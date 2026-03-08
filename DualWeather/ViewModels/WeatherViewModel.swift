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
        switch weatherIconCode {
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

    var sfSymbolColor: Color {
        switch weatherIconCode {
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
