import 'package:cloud_firestore/cloud_firestore.dart';

class DevotionalPost {
  final String id;
  final String? imageUrl;
  final String? templateId;
  final String? textContent;
  final String? caption;
  final DateTime scheduledFor;
  final bool isPublished;
  final List<String> topicIds;
  final String type; // 'uploaded' or 'template'
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime? updatedAt;

  const DevotionalPost({
    required this.id,
    this.imageUrl,
    this.templateId,
    this.textContent,
    this.caption,
    required this.scheduledFor,
    this.isPublished = false,
    this.topicIds = const [],
    this.type = 'uploaded',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.updatedAt,
  });

  factory DevotionalPost.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return DevotionalPost(
      id: doc.id,
      imageUrl: data['imageUrl'] as String?,
      templateId: data['templateId'] as String?,
      textContent: data['textContent'] as String?,
      caption: data['caption'] as String?,
      scheduledFor: (data['scheduledFor'] as Timestamp).toDate(),
      isPublished: data['isPublished'] as bool? ?? false,
      topicIds: List<String>.from(data['topicIds'] ?? []),
      type: data['type'] as String? ?? 'uploaded',
      likesCount: data['likesCount'] as int? ?? 0,
      commentsCount: data['commentsCount'] as int? ?? 0,
      viewsCount: data['viewsCount'] as int? ?? 0,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'templateId': templateId,
      'textContent': textContent,
      'caption': caption,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'isPublished': isPublished,
      'topicIds': topicIds,
      'type': type,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'viewsCount': viewsCount,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  DevotionalPost copyWith({
    String? id,
    String? imageUrl,
    String? templateId,
    String? textContent,
    String? caption,
    DateTime? scheduledFor,
    bool? isPublished,
    List<String>? topicIds,
    String? type,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    DateTime? updatedAt,
  }) {
    return DevotionalPost(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      templateId: templateId ?? this.templateId,
      textContent: textContent ?? this.textContent,
      caption: caption ?? this.caption,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isPublished: isPublished ?? this.isPublished,
      topicIds: topicIds ?? this.topicIds,
      type: type ?? this.type,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return Comment(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'User',
      photoUrl: data['photoUrl'] as String?,
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class AppUser {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final String role; // 'user' or 'admin'
  final bool notificationsEnabled;
  final bool isBanned;
  final List<String> fcmTokens;

  const AppUser({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.role = 'user',
    this.notificationsEnabled = true,
    this.isBanned = false,
    this.fcmTokens = const [],
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'User',
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: data['role'] as String? ?? 'user',
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      isBanned: data['isBanned'] as bool? ?? false,
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'notificationsEnabled': notificationsEnabled,
      'isBanned': isBanned,
      'fcmTokens': fcmTokens,
    };
  }

  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? role,
    bool? notificationsEnabled,
    bool? isBanned,
    List<String>? fcmTokens,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isBanned: isBanned ?? this.isBanned,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }
}
