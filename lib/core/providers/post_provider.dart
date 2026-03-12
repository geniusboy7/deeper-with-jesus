import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/devotional_post.dart';
import '../services/post_service.dart';

// ---------------------------------------------------------------------------
// Service singleton
// ---------------------------------------------------------------------------

final postServiceProvider = Provider<PostService>((ref) => PostService());

// ---------------------------------------------------------------------------
// All posts (admin dashboard)
// ---------------------------------------------------------------------------

/// Stream of ALL posts (published + scheduled), ordered by date descending.
final allPostsProvider = StreamProvider<List<DevotionalPost>>((ref) {
  return ref.watch(postServiceProvider).watchAllPosts();
});

// ---------------------------------------------------------------------------
// Published posts
// ---------------------------------------------------------------------------

/// Stream of published-only posts, ordered by date descending.
final publishedPostsProvider = StreamProvider<List<DevotionalPost>>((ref) {
  return ref.watch(postServiceProvider).watchPublishedPosts();
});

// ---------------------------------------------------------------------------
// Post for a specific date
// ---------------------------------------------------------------------------

/// Family provider: stream the published post for a given date.
final postForDateProvider =
    StreamProvider.family<DevotionalPost?, DateTime>((ref, date) {
  return ref.watch(postServiceProvider).watchPostForDate(date);
});

// ---------------------------------------------------------------------------
// Posts by topic
// ---------------------------------------------------------------------------

/// Family provider: stream published posts filtered by topic ID.
final postsByTopicProvider =
    StreamProvider.family<List<DevotionalPost>, String>((ref, topicId) {
  return ref.watch(postServiceProvider).watchPostsByTopic(topicId);
});

// ---------------------------------------------------------------------------
// Comments for a post
// ---------------------------------------------------------------------------

/// Family provider: stream all comments for a given post ID.
final commentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, postId) {
  return ref.watch(postServiceProvider).watchComments(postId);
});
