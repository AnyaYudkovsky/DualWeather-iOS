import Foundation

enum WeatherError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
}

class WeatherService {
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let forecastURL = "https://api.openweathermap.org/data/2.5/forecast"

    func fetchWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "appid", value: APIConfig.apiKey),
            URLQueryItem(name: "units", value: "standard")
        ]

        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw WeatherError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WeatherError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(WeatherResponse.self, from: data)
        } catch {
            throw WeatherError.decodingError(error)
        }
    }

    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
        var components = URLComponents(string: forecastURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "appid", value: APIConfig.apiKey),
            URLQueryItem(name: "units", value: "standard"),
            URLQueryItem(name: "cnt", value: "40")
        ]

        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw WeatherError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WeatherError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(ForecastResponse.self, from: data)
        } catch {
            throw WeatherError.decodingError(error)
        }
    }
}
