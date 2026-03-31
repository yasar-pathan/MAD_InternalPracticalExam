import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String title;
  final String lowercaseTitle;
  final String description;
  final double price;
  final List<String> images;
  final String category;
  final String sellerId;
  final String status;
  final DateTime createdAt;
  final String location;

  ListingModel({
    required this.id,
    required this.title,
    required this.lowercaseTitle,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    required this.sellerId,
    required this.status,
    required this.createdAt,
    required this.location,
  });

  ListingModel copyWith({
    String? id,
    String? title,
    String? lowercaseTitle,
    String? description,
    double? price,
    List<String>? images,
    String? category,
    String? sellerId,
    String? status,
    DateTime? createdAt,
    String? location,
  }) {
    return ListingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      lowercaseTitle: lowercaseTitle ?? this.lowercaseTitle,
      description: description ?? this.description,
      price: price ?? this.price,
      images: images ?? this.images,
      category: category ?? this.category,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'lowercaseTitle': lowercaseTitle,
      'description': description,
      'price': price,
      'images': images,
      'category': category,
      'sellerId': sellerId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'location': location,
    };
  }

  factory ListingModel.fromMap(Map<String, dynamic> map, String docId) {
    return ListingModel(
      id: docId,
      title: map['title'] ?? '',
      lowercaseTitle: map['lowercaseTitle'] ?? (map['title']?.toString().toLowerCase() ?? ''),
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      images: List<String>.from(map['images'] ?? []),
      category: map['category'] ?? '',
      sellerId: map['sellerId'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: _toDateTime(map['createdAt']),
      location: map['location'] ?? '',
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
