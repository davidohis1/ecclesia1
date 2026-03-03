import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String username;
  final String? profilePicUrl;
  final String? bio;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? churchAttending;
  final bool givenLifeToChrist;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;
  final bool isVerified;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.username,
    this.profilePicUrl,
    this.bio,
    this.gender,
    this.dateOfBirth,
    this.churchAttending,
    this.givenLifeToChrist = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    required this.createdAt,
    this.isVerified = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      profilePicUrl: map['profilePicUrl'],
      bio: map['bio'],
      gender: map['gender'],
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : null,
      churchAttending: map['churchAttending'],
      givenLifeToChrist: map['givenLifeToChrist'] ?? false,
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'username': username,
      'profilePicUrl': profilePicUrl,
      'bio': bio,
      'gender': gender,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'churchAttending': churchAttending,
      'givenLifeToChrist': givenLifeToChrist,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
    };
  }

  UserModel copyWith({
    String? name,
    String? profilePicUrl,
    String? bio,
    String? gender,
    DateTime? dateOfBirth,
    String? churchAttending,
    bool? givenLifeToChrist,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isVerified,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      username: username,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      churchAttending: churchAttending ?? this.churchAttending,
      givenLifeToChrist: givenLifeToChrist ?? this.givenLifeToChrist,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      createdAt: createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
