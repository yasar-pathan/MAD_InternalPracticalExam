import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String reviewerId;
  final String targetUserId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.targetUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  ReviewModel copyWith({
    String? id,
    String? reviewerId,
    String? targetUserId,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      targetUserId: targetUserId ?? this.targetUserId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewerId': reviewerId,
      'targetUserId': targetUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReviewModel(
      id: docId,
      reviewerId: map['reviewerId'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: _toDateTime(map['createdAt']),
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
