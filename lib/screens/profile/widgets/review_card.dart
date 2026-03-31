import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/review_model.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, required this.reviewerName, this.reviewerAvatar});

  final ReviewModel review;
  final String reviewerName;
  final String? reviewerAvatar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: reviewerAvatar != null ? NetworkImage(reviewerAvatar!) : null,
                  child: reviewerAvatar == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(reviewerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(DateFormat('dd MMM yyyy').format(review.createdAt), style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating.round() ? Icons.star : Icons.star_border,
                  size: 18,
                  color: Colors.amber,
                ),
              ),
            ),
            if (review.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment),
            ],
          ],
        ),
      ),
    );
  }
}
