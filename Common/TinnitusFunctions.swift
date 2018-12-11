import Foundation

func getUserName(deviceName: String) -> String {
    return deviceName.split(separator: " ").first.map(String.init)?.lowercased() ?? ""
}
