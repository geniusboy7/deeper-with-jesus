import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'notification_provider.dart';

// -----------------------------------------------------------------------------
// Session guard — ensures we only increment once per cold start
// -----------------------------------------------------------------------------

final _streakIncrementedProvider = NotifierProvider<_StreakGuard, bool>(
  _StreakGuard.new,
);

class _StreakGuard extends Notifier<bool> {
  @override
  bool build() => false;

  void markDone() => state = true;
}

// -----------------------------------------------------------------------------
// Milestone thresholds
// -----------------------------------------------------------------------------

const _milestones = {7, 30, 90, 365};

// -----------------------------------------------------------------------------
// Streak init provider
// -----------------------------------------------------------------------------

/// Watches the current AppUser and increments `appOpens` once per session.
/// If the new count hits a milestone, fires a local notification.
final streakInitProvider = FutureProvider<void>((ref) async {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser == null) return;

  // Only run once per cold start
  final alreadyIncremented = ref.read(_streakIncrementedProvider);
  if (alreadyIncremented) return;
  ref.read(_streakIncrementedProvider.notifier).markDone();

  // Atomically increment appOpens in Firestore
  final userService = ref.read(userServiceProvider);
  await userService.updateUserFields(appUser.uid, {
    'appOpens': FieldValue.increment(1),
  });

  // Compute new count locally
  final newCount = appUser.appOpens + 1;

  // Check for milestone
  if (_milestones.contains(newCount)) {
    final notifService = ref.read(notificationServiceProvider);
    await notifService.showStreakMilestone(newCount);
  }
});
