import Foundation

struct APIConfig {
    static var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["OpenWeatherAPIKey"] as? String else {
            print("⚠️ Warning: OpenWeatherAPIKey not found in Secrets.plist. Copy Secrets.plist.template to Secrets.plist and add your API key.")
            return ""
        }
        return key
    }
}
