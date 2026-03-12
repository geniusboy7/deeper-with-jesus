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

    // On iOS, the APNs token must be available before getToken() or
    // topic subscriptions will silently fail. Wait for it (with timeout).
    await _waitForApnsToken();

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

  /// On iOS, APNs token delivery is async. FCM's getToken() and topic
  /// subscriptions silently fail without it. Poll briefly until it arrives.
  Future<void> _waitForApnsToken() async {
    // Only relevant on iOS — Android doesn't use APNs.
    for (int i = 0; i < 10; i++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) return;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    // If we still don't have one after 5s, continue anyway — the
    // onTokenRefresh listener will pick it up later.
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
      // Store in a separate server-managed collection keyed by token.
      // This keeps FCM tokens out of the user document (which the user
      // can read) and lets Cloud Functions query tokens independently.
      await _firestore.collection('fcm_tokens').doc(token).set({
        'userId': userId,
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Collection or permissions might not be ready yet — ignore silently
    }
  }

  /// Remove the current device's FCM token (e.g. on sign-out).
  Future<void> removeToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('fcm_tokens').doc(token).delete();
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
        // Handle tap on local notification — validate postId format
        final payload = response.payload;
        if (payload != null &&
            _router != null &&
            _validPostId.hasMatch(payload)) {
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

  /// Firestore doc IDs: 1-128 chars, alphanumeric + underscores/hyphens.
  static final _validPostId = RegExp(r'^[a-zA-Z0-9_-]{1,128}$');

  void _handleNotificationTap(RemoteMessage message) {
    if (_router == null) return;

    final postId = message.data['postId'] as String?;
    if (postId == null || !_validPostId.hasMatch(postId)) return;

    final dateStr = message.data['scheduledFor'] as String?;
    // Only append date if it parses to a valid DateTime
    final query =
        (dateStr != null && DateTime.tryParse(dateStr) != null)
            ? '?date=$dateStr'
            : '';
    _router!.push('/post/$postId$query');
  }
}
