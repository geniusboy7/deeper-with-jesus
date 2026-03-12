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
    // Firebase is initialized by the Flutter plugin, but we need to set
    // the messaging delegate on the native side so APNs tokens are
    // forwarded to FCM.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // Register for remote notifications (required on iOS for APNs)
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    // Let FCM know about token refreshes
    Messaging.messaging().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Forward the APNs device token to FCM
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Called when FCM generates a new token
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    // The flutter_local_notifications plugin picks this up via onTokenRefresh
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
