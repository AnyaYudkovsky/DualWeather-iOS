import SwiftUI

struct DailyForecastView: View {
    @ObservedObject var viewModel: WeatherViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("5-DAY FORECAST")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                let days = viewModel.dailyForecast
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    DailyRowView(day: day, viewModel: viewModel)

                    if index < days.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

private struct DailyRowView: View {
    let day: DailyForecast
    let viewModel: WeatherViewModel

    var body: some View {
        HStack {
            Text(day.dayName)
                .frame(width: 90, alignment: .leading)
                .foregroundColor(.primary)

            Image(systemName: WeatherViewModel.sfSymbolName(for: day.icon))
                .font(.system(size: 22))
                .foregroundColor(WeatherViewModel.sfSymbolColor(for: day.icon))
                .frame(width: 30)

            if day.pop >= 0.1 {
                Text("\(Int(day.pop * 100))%")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(width: 40)
            } else {
                Spacer()
                    .frame(width: 40)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 0) {
                    Text(viewModel.forecastHighF(day))
                        .bold()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(" / ")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(viewModel.forecastHighC(day))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                HStack(spacing: 0) {
                    Text(viewModel.forecastLowF(day))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(" / ")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(viewModel.forecastLowC(day))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    DailyForecastView(viewModel: WeatherViewModel())
}
