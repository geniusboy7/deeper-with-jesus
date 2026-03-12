import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/devotional_post.dart';

class PostService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection('posts');

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  /// Create a new post document in Firestore. Returns the created post.
  Future<DevotionalPost> createPost(DevotionalPost post) async {
    final data = post.toFirestore();
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    final docRef = await _postsRef.add(data);
    final snap = await docRef.get();
    return DevotionalPost.fromFirestore(snap);
  }

  // ---------------------------------------------------------------------------
  // Upload image to Firebase Storage
  // ---------------------------------------------------------------------------

  /// Upload an image file to Firebase Storage and return the download URL.
  Future<String> uploadPostImage(File file) async {
    final fileName =
        'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('post_images/$fileName');

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Stream all published posts ordered by scheduledFor descending.
  Stream<List<DevotionalPost>> watchPublishedPosts() {
    return _postsRef
        .where('isPublished', isEqualTo: true)
        .orderBy('scheduledFor', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DevotionalPost.fromFirestore(d)).toList());
  }

  /// Stream all posts (published + scheduled) for admin dashboard.
  Stream<List<DevotionalPost>> watchAllPosts() {
    return _postsRef
        .orderBy('scheduledFor', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DevotionalPost.fromFirestore(d)).toList());
  }

  /// Get the published post for a specific date (date-only comparison).
  /// If multiple posts exist for the same day, returns the one with the
  /// latest updatedAt timestamp.
  Stream<DevotionalPost?> watchPostForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _postsRef
        .where('isPublished', isEqualTo: true)
        .where('scheduledFor',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledFor', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final posts =
          snap.docs.map((d) => DevotionalPost.fromFirestore(d)).toList();
      // Sort by updatedAt descending — the most recently updated post wins
      posts.sort((a, b) {
        final aTime = a.updatedAt ?? a.scheduledFor;
        final bTime = b.updatedAt ?? b.scheduledFor;
        return bTime.compareTo(aTime);
      });
      return posts.first;
    });
  }

  /// Get posts filtered by topic.
  Stream<List<DevotionalPost>> watchPostsByTopic(String topicId) {
    return _postsRef
        .where('isPublished', isEqualTo: true)
        .where('topicIds', arrayContains: topicId)
        .orderBy('scheduledFor', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DevotionalPost.fromFirestore(d)).toList());
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  /// Update a post document. Automatically sets updatedAt to now.
  Future<void> updatePost(DevotionalPost post) async {
    final data = post.toFirestore();
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _postsRef.doc(post.id).update(data);
  }

  /// Publish a post immediately.
  Future<void> publishPost(String postId) async {
    await _postsRef.doc(postId).update({'isPublished': true});
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  /// Delete a post document.
  Future<void> deletePost(String postId) async {
    await _postsRef.doc(postId).delete();
  }

  // ---------------------------------------------------------------------------
  // Comments (subcollection: posts/{postId}/comments)
  // ---------------------------------------------------------------------------

  /// Reference to the comments subcollection for a given post.
  CollectionReference<Map<String, dynamic>> _commentsRef(String postId) =>
      _postsRef.doc(postId).collection('comments');

  /// Add a comment to a post. Atomically increments `commentsCount`.
  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String displayName,
    String? photoUrl,
    required String text,
  }) async {
    final comment = Comment(
      id: '', // will be set by Firestore
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
      text: text,
      createdAt: DateTime.now(),
    );

    // Use a batch to add the comment and increment the count atomically
    final batch = _firestore.batch();

    final commentRef = _commentsRef(postId).doc();
    batch.set(commentRef, comment.toFirestore());

    batch.update(_postsRef.doc(postId), {
      'commentsCount': FieldValue.increment(1),
    });

    await batch.commit();

    final snap = await commentRef.get();
    return Comment.fromFirestore(snap);
  }

  /// Stream all comments for a post, ordered by creation time ascending.
  Stream<List<Comment>> watchComments(String postId) {
    return _commentsRef(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Comment.fromFirestore(d)).toList());
  }

  /// Delete a comment. Atomically decrements `commentsCount`.
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final batch = _firestore.batch();

    batch.delete(_commentsRef(postId).doc(commentId));

    batch.update(_postsRef.doc(postId), {
      'commentsCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }
}
