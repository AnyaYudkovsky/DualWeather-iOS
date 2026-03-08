import Foundation

struct WeatherResponse: Codable {
    let coord: Coordinates
    let weather: [WeatherCondition]
    let main: MainWeather
    let visibility: Int?
    let wind: Wind
    let clouds: CloudCoverage?
    let dt: Int
    let sys: Sys
    let name: String
}

struct MainWeather: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Double
    let humidity: Int

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
    }
}

struct Wind: Codable {
    let speed: Double
    let deg: Double?
}

struct WeatherCondition: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct CloudCoverage: Codable {
    let all: Int
}

struct Sys: Codable {
    let sunrise: Int
    let sunset: Int
    let country: String?
}

struct Coordinates: Codable {
    let lat: Double
    let lon: Double
}

// MARK: - Forecast Models

struct ForecastResponse: Codable {
    let list: [ForecastItem]
    let city: ForecastCity
}

struct ForecastItem: Codable, Identifiable {
    var id: Int { dt }
    let dt: Int
    let main: MainWeather
    let weather: [WeatherCondition]
    let wind: Wind
    let visibility: Int?
    let pop: Double
    let dtTxt: String

    enum CodingKeys: String, CodingKey {
        case dt, main, weather, wind, visibility, pop
        case dtTxt = "dt_txt"
    }
}

struct ForecastCity: Codable {
    let name: String
    let country: String
    let timezone: Int
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String
    let high: Double
    let low: Double
    let icon: String
    let description: String
    let pop: Double
}
