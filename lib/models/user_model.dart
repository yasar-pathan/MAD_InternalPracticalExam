import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? avatar;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final List<String> fcmTokens;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.avatar,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    this.fcmTokens = const [],
  });

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? avatar,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    List<String>? fcmTokens,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatar': avatar,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'fcmTokens': fcmTokens,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatar: map['avatar'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      createdAt: _toDateTime(map['createdAt']),
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
