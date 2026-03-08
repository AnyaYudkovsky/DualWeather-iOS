import SwiftUI

struct WeatherRowView: View {
    let label: String
    let imperialValue: String
    let metricValue: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)

                Text(imperialValue)
                    .foregroundColor(.primary)
                    .bold()

                Spacer()

                Text(metricValue)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 16)
        }
    }
}

#Preview {
    WeatherRowView(label: "Wind", imperialValue: "12 mph", metricValue: "19 km/h")
        .previewLayout(.sizeThatFits)
}
