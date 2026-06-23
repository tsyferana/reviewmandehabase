import 'package:review_app/utils/couleur.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'rating_stars.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.reviewText,
    this.reviewDate,
    this.photos = const [],
    this.onTap,
    this.onLikeTap,
    this.onReportTap,
    this.isLiked = false,
    this.likeCount = 0,
    this.ownerReply,
  });

  final String userName;
  final String userAvatar;
  final double rating;
  final String reviewText;
  final DateTime? reviewDate;
  final List<String> photos;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onReportTap;
  final bool isLiked;
  final int likeCount;
  final String? ownerReply;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  _UserAvatar(
                    avatarUrl: userAvatar,
                    name: userName,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 12),

                  // Name + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (reviewDate != null)
                          Text(
                            DateFormat('dd MMM yyyy', 'fr_FR').format(reviewDate!),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Rating + report
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RatingStars(rating: rating, size: 14),
                      if (onReportTap != null)
                        GestureDetector(
                          onTap: onReportTap,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.flag_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Review text with quote ────────────────────────────
              Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Text(
                      '"',
                      style: TextStyle(
                        fontSize: 36,
                        height: 0.8,
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      reviewText,
                      style: textTheme.bodySmall?.copyWith(
                        height: 1.55,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // ── Photos ────────────────────────────────────────────
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          photos[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ],

              // ── Owner reply ───────────────────────────────────────
              if (ownerReply != null && ownerReply!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.business_center_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Réponse du propriétaire',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ownerReply!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Footer actions ────────────────────────────────────
              const SizedBox(height: 12),
              Row(
                children: [
                  // Like button
                  GestureDetector(
                    onTap: onLikeTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isLiked
                            ? AppColors.error.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.6,
                              ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLiked
                              ? AppColors.error.withValues(alpha: 0.3)
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            size: 14,
                            color: isLiked
                                ? AppColors.error
                                : colorScheme.onSurfaceVariant,
                          ),
                          if (likeCount > 0) ...[
                            const SizedBox(width: 5),
                            Text(
                              '$likeCount',
                              style: textTheme.labelSmall?.copyWith(
                                color: isLiked
                                    ? AppColors.error
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.avatarUrl,
    required this.name,
    required this.colorScheme,
  });

  final String avatarUrl;
  final String name;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isValidUrl = avatarUrl.startsWith('http');

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundImage: isValidUrl ? NetworkImage(avatarUrl) : null,
        backgroundColor: colorScheme.primaryContainer,
        child: !isValidUrl
            ? Text(
                initial,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              )
            : null,
      ),
    );
  }
}
