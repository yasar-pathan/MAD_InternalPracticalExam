import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/listing_model.dart';
import '../../models/review_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/listing_service.dart';
import '../../services/review_service.dart';
import '../../services/storage_service.dart';
import 'widgets/review_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.uid});

  final String? uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final targetUid = uid ?? authUser?.uid;

    if (targetUid == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final isSelf = authUser?.uid == targetUid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isSelf ? 'My Profile' : 'Profile'),
          actions: [
            if (isSelf)
              IconButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Listings'),
              Tab(text: 'Sold'),
              Tab(text: 'Reviews Received'),
            ],
          ),
        ),
        body: FutureBuilder<UserModel?>(
          future: ref.read(reviewServiceProvider).getUser(targetUid),
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (user == null) {
              return const Center(child: Text('User not found'));
            }

            return Column(
              children: [
                _ProfileHeader(user: user, isSelf: isSelf),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ListingsTab(uid: targetUid, status: 'active'),
                      _ListingsTab(uid: targetUid, status: 'sold'),
                      _ReviewsTab(uid: targetUid),
                    ],
                  ),
                ),
                if (!isSelf && authUser != null)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openReviewSheet(context, ref, authUser.uid, targetUid),
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Leave a Review'),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openReviewSheet(BuildContext context, WidgetRef ref, String reviewerId, String targetUid) async {
    double rating = 5;
    final commentController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Leave a Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        onPressed: () => setState(() => rating = (index + 1).toDouble()),
                        icon: Icon(index < rating ? Icons.star : Icons.star_border, color: Colors.amber),
                      ),
                    ),
                  ),
                  TextField(
                    controller: commentController,
                    maxLength: 300,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Comment (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(reviewServiceProvider).submitReview(
                              reviewerId,
                              targetUid,
                              rating,
                              commentController.text.trim(),
                            );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Submit Review'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.user, required this.isSelf});

  final UserModel user;
  final bool isSelf;

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final url = await ref.read(storageServiceProvider).uploadUserAvatar(user.uid, File(picked.path));
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'avatar': url});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: isSelf ? () => _changeAvatar(context, ref) : null,
            child: CircleAvatar(
              radius: 40,
              backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
              child: user.avatar == null ? const Icon(Icons.person, size: 36) : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Member since ${user.createdAt.year}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text('⭐ ${user.rating.toStringAsFixed(1)} (${user.reviewCount} reviews)'),
        ],
      ),
    );
  }
}

class _ListingsTab extends ConsumerWidget {
  const _ListingsTab({required this.uid, required this.status});

  final String uid;
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<ListingModel>>(
      stream: ref.read(listingServiceProvider).getUserListings(uid),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final listings = all.where((l) => l.status == status).toList();

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (listings.isEmpty) {
          return Center(child: Text(status == 'active' ? 'No active listings' : 'No sold listings'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            return Card(
              child: ListTile(
                title: Text(listing.title),
                subtitle: Text('\$${listing.price.toStringAsFixed(0)}'),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<ReviewModel>>(
      stream: ref.read(reviewServiceProvider).getReviews(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data!;
        if (reviews.isEmpty) {
          return const Center(child: Text('No reviews yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return FutureBuilder(
              future: ref.read(reviewServiceProvider).getUser(review.reviewerId),
              builder: (context, userSnap) {
                final reviewer = userSnap.data;
                return ReviewCard(
                  review: review,
                  reviewerName: reviewer?.name ?? 'User',
                  reviewerAvatar: reviewer?.avatar,
                );
              },
            );
          },
        );
      },
    );
  }
}
