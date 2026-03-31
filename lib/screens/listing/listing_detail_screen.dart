import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/constants/app_colors.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../services/chat_service.dart';
import '../../services/listing_service.dart';
import '../../services/review_service.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingByIdProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Listing Details')),
      body: listingAsync.when(
        data: (listing) => _DetailBody(listing: listing),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Unable to load listing: $e')),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.listing});

  final ListingModel listing;

  Future<void> _startChat(BuildContext context, WidgetRef ref) async {
    final me = ref.read(authStateProvider).value;
    if (me == null) {
      context.go('/login');
      return;
    }

    try {
      final chatId = await ref.read(chatServiceProvider).getOrCreateChat(me.uid, listing.sellerId, listing.id);
      if (context.mounted) {
        context.push('/chat/$chatId', extra: {'otherUserId': listing.sellerId, 'otherUserName': 'Seller'});
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
      }
    }
  }

  Future<void> _deleteListing(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(listingServiceProvider).deleteListing(listing.id);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authStateProvider).value?.uid;
    final isOwner = currentUid != null && currentUid == listing.sellerId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            itemCount: listing.images.isEmpty ? 1 : listing.images.length,
            itemBuilder: (context, index) {
              if (listing.images.isEmpty) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 48, color: Colors.grey),
                );
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: listing.images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(listing.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('\$${listing.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 26, color: AppColors.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(listing.category)),
            Chip(label: Text(listing.location)),
            Chip(label: Text('Posted ${timeago.format(listing.createdAt)}')),
          ],
        ),
        const SizedBox(height: 14),
        Text(listing.description),
        const SizedBox(height: 16),
        FutureBuilder(
          future: ref.read(reviewServiceProvider).getUser(listing.sellerId),
          builder: (context, snapshot) {
            final seller = snapshot.data;
            return Card(
              child: ListTile(
                onTap: () => context.push('/profile/${listing.sellerId}'),
                leading: CircleAvatar(
                  backgroundImage: seller?.avatar != null ? CachedNetworkImageProvider(seller!.avatar!) : null,
                  child: seller?.avatar == null ? const Icon(Icons.person) : null,
                ),
                title: Text(seller?.name ?? 'Seller'),
                subtitle: Text('Rating: ${(seller?.rating ?? 0).toStringAsFixed(1)} (${seller?.reviewCount ?? 0} reviews)'),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (isOwner) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/edit-listing/${listing.id}'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _deleteListing(context, ref),
                  icon: const Icon(Icons.delete),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ] else ...[
          ElevatedButton.icon(
            onPressed: () => _startChat(context, ref),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Chat with Seller'),
          ),
        ],
      ],
    );
  }
}
