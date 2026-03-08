import SwiftUI

struct CurrentWeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel

    var body: some View {
        Group {
            switch viewModel.locationStatus {
            case .waiting, .loading:
                loadingView
            case .error(let message):
                errorView(message: message)
            case .loaded:
                loadedView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Loading State

    private var loadingView: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
            }

            Text(viewModel.locationStatus.message)
                .foregroundColor(.gray)

            if viewModel.errorMessage != nil {
                Button("Retry") {
                    viewModel.refreshWeather()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Error State

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)

            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                viewModel.refreshWeather()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Loaded State

    private var loadedView: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                temperatureSection
                feelsLikeRow

                if viewModel.forecastData != nil {
                    HourlyForecastView(viewModel: viewModel)
                        .padding(.top, 8)

                    DailyForecastView(viewModel: viewModel)
                        .padding(.top, 8)
                }

                detailsSection
                footerSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.cityName)
                .font(.largeTitle)
                .bold()

            Image(systemName: viewModel.sfSymbolName)
                .font(.system(size: 80))
                .foregroundColor(viewModel.sfSymbolColor)
                .shadow(color: viewModel.sfSymbolColor.opacity(0.4), radius: 8, x: 0, y: 4)

            Text(viewModel.weatherDescription)
                .font(.title3)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Temperature

    private var temperatureSection: some View {
        HStack(spacing: 0) {
            Text(viewModel.tempF)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 60)

            Text(viewModel.tempC)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Feels Like

    private var feelsLikeRow: some View {
        Text("Feels like \(viewModel.feelsLikeF) / \(viewModel.feelsLikeC)")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    // MARK: - Details Card

    private var detailsSection: some View {
        VStack(spacing: 0) {
            WeatherRowView(
                label: "Wind",
                imperialValue: viewModel.windMph,
                metricValue: viewModel.windKmh
            )
            WeatherRowView(
                label: "Visibility",
                imperialValue: viewModel.visibilityMiles,
                metricValue: viewModel.visibilityKm
            )
            WeatherRowView(
                label: "Pressure",
                imperialValue: viewModel.pressureInHg,
                metricValue: viewModel.pressureHpa
            )
            WeatherRowView(
                label: "Humidity",
                imperialValue: viewModel.humidity,
                metricValue: viewModel.humidity
            )
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Footer

    private var footerSection: some View {
        Text(viewModel.lastUpdated)
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.bottom, 16)
    }
}

#Preview {
    CurrentWeatherView(viewModel: WeatherViewModel())
}
