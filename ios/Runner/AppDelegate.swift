import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Let Flutter + plugins initialize first (firebase_core configures Firebase here)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Now that Firebase is initialized by the Flutter plugin, set native delegates
    // so APNs tokens are forwarded to FCM.
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self

    // Register for remote notifications (required on iOS for APNs token)
    application.registerForRemoteNotifications()

    return result
  }

  // Forward the APNs device token to FCM
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Explicitly set the APNs token so FCM can map it to an FCM token
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Called when FCM generates or refreshes a token
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    // The firebase_messaging Flutter plugin picks this up via onTokenRefresh
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
