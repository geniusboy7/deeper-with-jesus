import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import 'auth_provider.dart';

// -----------------------------------------------------------------------------
// Service singleton
// -----------------------------------------------------------------------------

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

// -----------------------------------------------------------------------------
// Auto-initialize notifications when user signs in
// -----------------------------------------------------------------------------

/// Watches the current AppUser and initializes the notification service
/// when a user is available. Also manages topic subscription based on
/// the user's `notificationsEnabled` preference.
final notificationInitProvider = FutureProvider<void>((ref) async {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser == null) return;

  final notifService = ref.read(notificationServiceProvider);
  await notifService.initialize(appUser.uid);
  await notifService.handleTopicSubscription(appUser.notificationsEnabled);
});
