import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool read;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.read,
  });

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? read,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: _toDateTime(map['timestamp']),
      read: map['read'] ?? false,
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
