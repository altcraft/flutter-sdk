import Foundation
import AltcraftCore

class JWTProvider: JWTInterface {
    private let suiteName = "group.altcraft.flutter.app"
    private let key = "JWT_KEY"

    func getToken() -> String? {
        return UserDefaults(suiteName: suiteName)?.string(forKey: key)
    }
}
