import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review_model.dart';
import '../models/user_model.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReview(String reviewerId, String targetUid, double rating, String comment) async {
    final ref = _firestore.collection('reviews').doc();
    await ref.set({
      'reviewerId': reviewerId,
      'targetUserId': targetUid,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await updateUserRating(targetUid);
  }

  Stream<List<ReviewModel>> getReviews(String targetUid) {
    return _firestore
        .collection('reviews')
        .where('targetUserId', isEqualTo: targetUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateUserRating(String targetUid) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('targetUserId', isEqualTo: targetUid)
        .get();

    final reviews = snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data(), doc.id)).toList();
    if (reviews.isEmpty) {
      await _firestore.collection('users').doc(targetUid).update({'rating': 0, 'reviewCount': 0});
      return;
    }

    final avg = reviews.fold<double>(0, (acc, item) => acc + item.rating) / reviews.length;
    await _firestore.collection('users').doc(targetUid).update({
      'rating': avg,
      'reviewCount': reviews.length,
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserModel.fromMap(doc.data()!, doc.id);
  }
}
