import 'package:cloud_firestore/cloud_firestore.dart';

// ── REEL ─────────────────────────────────────────────────────────────────────
class ReelModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String? authorProfilePic;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? caption;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;

  ReelModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    this.authorProfilePic,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    required this.createdAt,
  });

  factory ReelModel.fromMap(String id, Map<String, dynamic> map) {
    return ReelModel(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorProfilePic: map['authorProfilePic'],
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      caption: map['caption'],
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      viewsCount: map['viewsCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorUsername': authorUsername,
        'authorProfilePic': authorProfilePic,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'viewsCount': viewsCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ── LIBRARY DOC ───────────────────────────────────────────────────────────────
class LibraryDoc {
  final String id;
  final String uploaderId;
  final String uploaderName;
  final String title;
  final String? description;
  final String pdfUrl;
  final String? coverUrl;
  final String category;
  final int pages;
  final int downloadCount;
  final DateTime uploadedAt;

  LibraryDoc({
    required this.id,
    required this.uploaderId,
    required this.uploaderName,
    required this.title,
    this.description,
    required this.pdfUrl,
    this.coverUrl,
    this.category = 'General',
    this.pages = 0,
    this.downloadCount = 0,
    required this.uploadedAt,
  });

  factory LibraryDoc.fromMap(String id, Map<String, dynamic> map) {
    return LibraryDoc(
      id: id,
      uploaderId: map['uploaderId'] ?? '',
      uploaderName: map['uploaderName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      pdfUrl: map['pdfUrl'] ?? '',
      coverUrl: map['coverUrl'],
      category: map['category'] ?? 'General',
      pages: map['pages'] ?? 0,
      downloadCount: map['downloadCount'] ?? 0,
      uploadedAt: map['uploadedAt'] != null
          ? (map['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uploaderId': uploaderId,
        'uploaderName': uploaderName,
        'title': title,
        'description': description,
        'pdfUrl': pdfUrl,
        'coverUrl': coverUrl,
        'category': category,
        'pages': pages,
        'downloadCount': downloadCount,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
      };
}

// ── DISCUSSION ────────────────────────────────────────────────────────────────
class DiscussionModel {
  final String id;
  final String creatorId;
  final String creatorName;
  final String? creatorProfilePic;
  final String title;
  final String? description;
  final int membersCount;
  final int messagesCount;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final bool isActive;
  final String? topic;

  DiscussionModel({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    this.creatorProfilePic,
    required this.title,
    this.description,
    this.membersCount = 0,
    this.messagesCount = 0,
    required this.createdAt,
    this.lastMessageAt,
    this.isActive = true,
    this.topic,
  });

  factory DiscussionModel.fromMap(String id, Map<String, dynamic> map) {
    return DiscussionModel(
      id: id,
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      creatorProfilePic: map['creatorProfilePic'],
      title: map['title'] ?? '',
      description: map['description'],
      membersCount: map['membersCount'] ?? 0,
      messagesCount: map['messagesCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessageAt: map['lastMessageAt'] != null
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
      topic: map['topic'],
    );
  }

  Map<String, dynamic> toMap() => {
        'creatorId': creatorId,
        'creatorName': creatorName,
        'creatorProfilePic': creatorProfilePic,
        'title': title,
        'description': description,
        'membersCount': membersCount,
        'messagesCount': messagesCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastMessageAt': lastMessageAt != null
            ? Timestamp.fromDate(lastMessageAt!)
            : null,
        'isActive': isActive,
        'topic': topic,
      };
}

class DiscussionMessage {
  final String id;
  final String discussionId;
  final String senderId;
  final String senderName;
  final String? senderProfilePic;
  final String? text;
  final String? imageUrl;
  final DateTime sentAt;

  DiscussionMessage({
    required this.id,
    required this.discussionId,
    required this.senderId,
    required this.senderName,
    this.senderProfilePic,
    this.text,
    this.imageUrl,
    required this.sentAt,
  });

  factory DiscussionMessage.fromMap(String id, Map<String, dynamic> map) {
    return DiscussionMessage(
      id: id,
      discussionId: map['discussionId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderProfilePic: map['senderProfilePic'],
      text: map['text'],
      imageUrl: map['imageUrl'],
      sentAt: map['sentAt'] != null
          ? (map['sentAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'discussionId': discussionId,
        'senderId': senderId,
        'senderName': senderName,
        'senderProfilePic': senderProfilePic,
        'text': text,
        'imageUrl': imageUrl,
        'sentAt': Timestamp.fromDate(sentAt),
      };
}

// ── AUDIO ─────────────────────────────────────────────────────────────────────
class AudioModel {
  final String id;
  final String uploaderId;
  final String uploaderName;
  final String? uploaderProfilePic;
  final String title;
  final String? artist;
  final String? album;
  final String audioUrl;
  final String? coverUrl;
  final String category;
  final int durationSeconds;
  final int playCount;
  final int downloadCount;
  final DateTime uploadedAt;

  AudioModel({
    required this.id,
    required this.uploaderId,
    required this.uploaderName,
    this.uploaderProfilePic,
    required this.title,
    this.artist,
    this.album,
    required this.audioUrl,
    this.coverUrl,
    this.category = 'Worship',
    this.durationSeconds = 0,
    this.playCount = 0,
    this.downloadCount = 0,
    required this.uploadedAt,
  });

  factory AudioModel.fromMap(String id, Map<String, dynamic> map) {
    return AudioModel(
      id: id,
      uploaderId: map['uploaderId'] ?? '',
      uploaderName: map['uploaderName'] ?? '',
      uploaderProfilePic: map['uploaderProfilePic'],
      title: map['title'] ?? '',
      artist: map['artist'],
      album: map['album'],
      audioUrl: map['audioUrl'] ?? '',
      coverUrl: map['coverUrl'],
      category: map['category'] ?? 'Worship',
      durationSeconds: map['durationSeconds'] ?? 0,
      playCount: map['playCount'] ?? 0,
      downloadCount: map['downloadCount'] ?? 0,
      uploadedAt: map['uploadedAt'] != null
          ? (map['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uploaderId': uploaderId,
        'uploaderName': uploaderName,
        'uploaderProfilePic': uploaderProfilePic,
        'title': title,
        'artist': artist,
        'album': album,
        'audioUrl': audioUrl,
        'coverUrl': coverUrl,
        'category': category,
        'durationSeconds': durationSeconds,
        'playCount': playCount,
        'downloadCount': downloadCount,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
      };
}

// ── DIRECT MESSAGE ────────────────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final DateTime sentAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.sentAt,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'],
      imageUrl: map['imageUrl'],
      sentAt: map['sentAt'] != null
          ? (map['sentAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        'text': text,
        'imageUrl': imageUrl,
        'sentAt': Timestamp.fromDate(sentAt),
        'isRead': isRead,
      };
}

class ChatConversation {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;

  ChatConversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantPhotos,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCounts = const {},
  });

  factory ChatConversation.fromMap(String id, Map<String, dynamic> map) {
    return ChatConversation(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantPhotos:
          Map<String, String?>.from(map['participantPhotos'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageAt: map['lastMessageAt'] != null
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'participantIds': participantIds,
        'participantNames': participantNames,
        'participantPhotos': participantPhotos,
        'lastMessage': lastMessage,
        'lastMessageAt':
            lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
        'unreadCounts': unreadCounts,
      };
}
