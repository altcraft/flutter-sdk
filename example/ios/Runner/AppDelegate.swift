import Flutter
import UIKit
import AltcraftCore
import AltcraftInApp
import AltcraftPush
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AltcraftSDK.setAppGroup(groupName: "group.altcraft.flutter.app")
        AltcraftSDK.auth.setJWTProvider(provider: JWTProvider())
        AltcraftSDK.push.token.setAPNSTokenProvider(APNSProvider())
        AltcraftSDK.push.notificationManager.registerForPushNotifications(for: application)

        // The default `open_app` trigger is fired by the SDK lifecycle tracker.
        // It must be registered natively, otherwise Flutter apps never receive
        // the default trigger. The screen is set here so placement checks pass
        // when the trigger fires.
        AltcraftSDK.inApp.setScreen(screen: "home")
        AltcraftSDK.inApp.registerLifecycleTracking()

        GeneratedPluginRegistrant.register(with: self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        setAPNsTokenInUserDefault(deviceToken)
        AltcraftSDK.push.token.getToken()
    }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
}
