import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GoRouter? _router;
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize FCM: request permissions, get token, set up handlers.
  Future<void> initialize(String userId) async {
    if (_initialized) return;
    _initialized = true;

    // Request notification permissions (shows system dialog on iOS & Android 13+)
    await _requestPermission();

    // Set up local notifications for foreground display
    await _initLocalNotifications();

    // Get and store FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _storeFcmToken(userId, token);
    }

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      _storeFcmToken(userId, newToken);
    });

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Set up notification tap handlers (background state)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly so the router is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage);
      });
    }
  }

  /// Attach the GoRouter instance for deep linking from notification taps.
  void setRouter(GoRouter router) {
    _router = router;
  }

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Topic subscription
  // ---------------------------------------------------------------------------

  /// Subscribe or unsubscribe from the `new_posts` FCM topic.
  Future<void> handleTopicSubscription(bool enabled) async {
    if (enabled) {
      await _messaging.subscribeToTopic('new_posts');
    } else {
      await _messaging.unsubscribeFromTopic('new_posts');
    }
  }

  // ---------------------------------------------------------------------------
  // FCM token storage
  // ---------------------------------------------------------------------------

  Future<void> _storeFcmToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (_) {
      // User doc might not exist yet — ignore silently
    }
  }

  /// Remove the current device's FCM token (e.g. on sign-out).
  Future<void> removeToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Local notifications (foreground display)
  // ---------------------------------------------------------------------------

  Future<void> _initLocalNotifications() async {
    // Android init
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS init
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle tap on local notification
        final payload = response.payload;
        if (payload != null && _router != null) {
          _router!.push('/post/$payload');
        }
      },
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'devotional_posts',
      'Devotional Posts',
      description: 'Notifications for new devotional posts',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Streaks milestone channel
    const streaksChannel = AndroidNotificationChannel(
      'streaks',
      'Streaks',
      description: 'Milestone streak notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(streaksChannel);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final postId = message.data['postId'] as String?;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'devotional_posts',
          'Devotional Posts',
          channelDescription: 'Notifications for new devotional posts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: postId,
    );
  }

  // ---------------------------------------------------------------------------
  // Streak milestones
  // ---------------------------------------------------------------------------

  /// Show a local notification when the user hits a streak milestone.
  Future<void> showStreakMilestone(int count) async {
    await _localNotifications.show(
      'streak_$count'.hashCode,
      'Milestone Reached! 🔥',
      'You have read $count devotions! Keep going deeper with Jesus',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streaks',
          'Streaks',
          channelDescription: 'Milestone streak notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notification tap → deep link
  // ---------------------------------------------------------------------------

  void _handleNotificationTap(RemoteMessage message) {
    if (_router == null) return;

    final postId = message.data['postId'] as String?;
    final dateStr = message.data['scheduledFor'] as String?;

    if (postId != null) {
      final query = dateStr != null ? '?date=$dateStr' : '';
      _router!.push('/post/$postId$query');
    }
  }
}
