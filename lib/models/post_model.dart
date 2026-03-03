import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { text, image, video, mixed }

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String? authorProfilePic;
  final String? textContent;
  final List<String> mediaUrls;
  final PostType type;
  final String? backgroundGradientId;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final DateTime createdAt;
  final bool isAuthorVerified;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    this.authorProfilePic,
    this.textContent,
    this.mediaUrls = const [],
    required this.type,
    this.backgroundGradientId,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    required this.createdAt,
    this.isAuthorVerified = false,
  });

  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorProfilePic: map['authorProfilePic'],
      textContent: map['textContent'],
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      type: PostType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => PostType.text,
      ),
      backgroundGradientId: map['backgroundGradientId'],
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      sharesCount: map['sharesCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isAuthorVerified: map['isAuthorVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorUsername': authorUsername,
      'authorProfilePic': authorProfilePic,
      'textContent': textContent,
      'mediaUrls': mediaUrls,
      'type': type.name,
      'backgroundGradientId': backgroundGradientId,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAuthorVerified': isAuthorVerified,
    };
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String? authorProfilePic;
  final String content;
  final int likesCount;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    this.authorProfilePic,
    required this.content,
    this.likesCount = 0,
    required this.createdAt,
  });

  factory CommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommentModel(
      id: id,
      postId: map['postId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorProfilePic: map['authorProfilePic'],
      content: map['content'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorUsername': authorUsername,
      'authorProfilePic': authorProfilePic,
      'content': content,
      'likesCount': likesCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
