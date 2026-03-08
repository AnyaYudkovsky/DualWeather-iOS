import SwiftUI

struct HourlyForecastView: View {
    @ObservedObject var viewModel: WeatherViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HOURLY")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.hourlyForecast) { item in
                        HourlyCardView(item: item, viewModel: viewModel)
                    }
                }
            }
        }
    }
}

private struct HourlyCardView: View {
    let item: ForecastItem
    let viewModel: WeatherViewModel

    var body: some View {
        VStack(spacing: 6) {
            Text(viewModel.forecastTime(item))
                .font(.caption)
                .foregroundColor(.secondary)

            Image(systemName: WeatherViewModel.sfSymbolName(for: item.weather.first?.icon ?? ""))
                .font(.system(size: 28))
                .foregroundColor(WeatherViewModel.sfSymbolColor(for: item.weather.first?.icon ?? ""))

            Text(viewModel.forecastTempF(item))
                .font(.subheadline)
                .bold()
                .foregroundColor(.primary)

            Text(viewModel.forecastTempC(item))
                .font(.caption)
                .foregroundColor(.secondary)

            if let pop = viewModel.forecastPop(item) {
                Text(pop)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 70)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    HourlyForecastView(viewModel: WeatherViewModel())
}
