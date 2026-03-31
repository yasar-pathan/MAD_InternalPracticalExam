class OrderModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String listingId;
  final String status;
  final String? paymentId;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.listingId,
    required this.status,
    this.paymentId,
    required this.createdAt,
  });

  OrderModel copyWith({
    String? id,
    String? buyerId,
    String? sellerId,
    String? listingId,
    String? status,
    String? paymentId,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      listingId: listingId ?? this.listingId,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'listingId': listingId,
      'status': status,
      'paymentId': paymentId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    return OrderModel(
      id: docId,
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      listingId: map['listingId'] ?? '',
      status: map['status'] ?? 'pending',
      paymentId: map['paymentId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
