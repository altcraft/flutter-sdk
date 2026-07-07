import Flutter
import UIKit
import Altcraft
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AltcraftSDK.shared.setAppGroup(groupName: "group.altcraft.flutter.app")
        AltcraftSDK.shared.setJWTProvider(provider: JWTProvider())
        AltcraftSDK.shared.pushTokenFunctions.setAPNSTokenProvider(APNSProvider())
        AltcraftSDK.shared.notificationManager.registerForPushNotifications(for: application)

        GeneratedPluginRegistrant.register(with: self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        setAPNsTokenInUserDefault(deviceToken)
        AltcraftSDK.shared.pushTokenFunctions.getPushToken()
    }
}
