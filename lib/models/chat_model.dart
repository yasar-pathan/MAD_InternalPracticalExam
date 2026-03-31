import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String listingId;
  final Map<String, int> unreadCounts;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.listingId,
    this.unreadCounts = const {},
  });

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? listingId,
    Map<String, int>? unreadCounts,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      listingId: listingId ?? this.listingId,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'listingId': listingId,
      'unreadCounts': unreadCounts,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatModel(
      id: docId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: _toDateTime(map['lastMessageTime']),
      listingId: map['listingId'] ?? '',
      unreadCounts: Map<String, int>.from((map['unreadCounts'] ?? {}).map((k, v) => MapEntry(k.toString(), (v ?? 0) as int))),
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
