import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/listing_model.dart';

final listingServiceProvider = Provider<ListingService>((ref) => ListingService());

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ListingModel>> getListings({String? category, int limit = 50}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<ListingModel> getListingById(String id) async {
    final doc = await _firestore.collection('listings').doc(id).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Listing not found');
    }
    return ListingModel.fromMap(doc.data()!, doc.id);
  }

  Future<String> createListing(ListingModel listing) async {
    final ref = _firestore.collection('listings').doc();
    final data = listing.copyWith(id: ref.id, lowercaseTitle: listing.title.toLowerCase()).toMap();
    await ref.set(data);
    return ref.id;
  }

  Future<void> updateListing(ListingModel listing) async {
    await _firestore.collection('listings').doc(listing.id).update(
          listing.copyWith(lowercaseTitle: listing.title.toLowerCase()).toMap(),
        );
  }

  Future<void> deleteListing(String id) async {
    await _firestore.collection('listings').doc(id).delete();
  }

  Stream<List<ListingModel>> getUserListings(String uid) {
    return _firestore
        .collection('listings')
        .where('sellerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ListingModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<ListingModel>> searchListings({
    required String query,
    String? category,
    double minPrice = 0,
    double maxPrice = 100000,
    String sortBy = 'Newest',
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .where('lowercaseTitle', isGreaterThanOrEqualTo: query)
        .where('lowercaseTitle', isLessThanOrEqualTo: '$query\uf8ff');

    if (category != null && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }

    final snap = await q.get();
    final items = snap.docs
        .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
        .where((item) => item.price >= minPrice && item.price <= maxPrice)
        .toList();

    if (sortBy == 'Price Low-High') {
      items.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortBy == 'Price High-Low') {
      items.sort((a, b) => b.price.compareTo(a.price));
    } else {
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return items;
  }
}
