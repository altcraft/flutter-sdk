import Foundation
import Altcraft

class JWTProvider: JWTInterface {
    private let suiteName = "group.altcraft.flutter.app"
    private let key = "JWT_KEY"
    private let defaultJWT = ""
    

    func getToken() -> String? {
        return UserDefaults(suiteName: suiteName)?.string(forKey: key) ?? defaultJWT
    }
}
