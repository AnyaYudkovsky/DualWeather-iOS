//
//  ContentView.swift
//  DualWeather
//
//  Created by Anya Yudkovsky on 3/8/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = WeatherViewModel()

    var body: some View {
        CurrentWeatherView(viewModel: viewModel)
            .onAppear {
                viewModel.requestLocation()
            }
            .refreshable {
                viewModel.refreshWeather()
            }
    }
}

#Preview {
    ContentView()
}
