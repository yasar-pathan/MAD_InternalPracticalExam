import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/listing_model.dart';
import '../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final String sellerName;

  const ListingCard({
    super.key,
    required this.listing,
    required this.sellerName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/listing/${listing.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: listing.images.isNotEmpty ? listing.images.first : '',
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textMain),
                  ),
                  const SizedBox(height: 4),
                  Text('\$${listing.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(sellerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(listing.createdAt),
                    style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
