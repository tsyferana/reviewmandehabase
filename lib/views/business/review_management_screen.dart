import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../controllers/review_controller.dart';
import '../../models/review_model.dart';
import '../../repositories/review_repository.dart';
import '../../services/supabase_data_service.dart';
import '../../widgets/report_review_dialog.dart';

enum ReviewFilterOption { all, unanswered, answered, reported }

enum ReviewSortingOption { recent, rating }

class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  static const routeName = '/business/reviews-management';

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  late final ReviewController _reviewController;

  ReviewFilterOption _filterOption = ReviewFilterOption.all;
  ReviewSortingOption _sortOption = ReviewSortingOption.recent;

  // Mock data: store reports
  final Set<String> _reportedReviews = {};

  @override
  void initState() {
    super.initState();
    _reviewController = ReviewController(ReviewRepository());
    _reviewController.addListener(_onReviewsChanged);
    _loadRealReviews();
  }

  Future<void> _loadRealReviews() async {
    try {
      // Need to import SupabaseDataService
      final biz = await SupabaseDataService().getUserBusiness();
      if (biz != null && mounted) {
        await _reviewController.loadReviews(biz['id']);
      }
    } catch (e) {
      debugPrint('Error loading real reviews: $e');
    }
  }

  @override
  void dispose() {
    _reviewController
      ..removeListener(_onReviewsChanged)
      ..dispose();
    super.dispose();
  }

  void _onReviewsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  List<ReviewModel> _getFilteredAndSortedReviews() {
    var filtered = _reviewController.reviews.toList();

    // Apply filter
    switch (_filterOption) {
      case ReviewFilterOption.all:
        break;
      case ReviewFilterOption.unanswered:
        filtered = filtered
            .where((r) => r.replies.isEmpty)
            .toList();
      case ReviewFilterOption.answered:
        filtered = filtered
            .where((r) => r.replies.isNotEmpty)
            .toList();
      case ReviewFilterOption.reported:
        filtered = filtered
            .where((r) => _reportedReviews.contains(r.id))
            .toList();
    }

    // Apply sort
    switch (_sortOption) {
      case ReviewSortingOption.recent:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ReviewSortingOption.rating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return filtered;
  }

  int _calculatePercentageAnswered() {
    if (_reviewController.reviews.isEmpty) return 0;
    final answered = _reviewController.reviews
        .where((r) => r.replies.isNotEmpty)
        .length;
    return ((answered / _reviewController.reviews.length) * 100).toInt();
  }

  double _calculateAverageRating() {
    if (_reviewController.reviews.isEmpty) return 0;
    final sum = _reviewController.reviews.fold<double>(
      0,
      (prev, r) => prev + r.rating,
    );
    return sum / _reviewController.reviews.length;
  }

  Future<void> _submitResponse(ReviewModel review, String response) async {
    if (response.trim().isEmpty) return;

    try {
      await _reviewController.addReplyToThread(review.id, response.trim(), 'owner');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réponse publiée avec succès.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _reportReview(ReviewModel review) async {
    showDialog(
      context: context,
      builder: (context) {
        return ReportReviewDialog(
          reviewId: review.id,
          onSubmit: (type, reason) async {
            await SupabaseDataService().createReport(review.id, type, reason);
            if (mounted) {
              setState(() => _reportedReviews.add(review.id));
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filteredReviews = _getFilteredAndSortedReviews();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des avis'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Stats
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _StatSmallCard(
                  label: 'Total avis',
                  value: '${_reviewController.reviews.length}',
                  icon: Icons.rate_review_rounded,
                  color: Colors.orange,
                ),
                _StatSmallCard(
                  label: 'Note moyenne',
                  value: _calculateAverageRating().toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                ),
                _StatSmallCard(
                  label: '% Répondus',
                  value: '${_calculatePercentageAnswered()}%',
                  icon: Icons.reply_rounded,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters and Sort
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _filterOption == ReviewFilterOption.all,
                          onSelected: (_) => setState(
                            () => _filterOption = ReviewFilterOption.all,
                          ),
                          label: const Text('Tous'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected:
                              _filterOption == ReviewFilterOption.unanswered,
                          onSelected: (_) => setState(
                            () => _filterOption = ReviewFilterOption.unanswered,
                          ),
                          label: const Text('Sans réponse'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected:
                              _filterOption == ReviewFilterOption.answered,
                          onSelected: (_) => setState(
                            () => _filterOption = ReviewFilterOption.answered,
                          ),
                          label: const Text('Avec réponse'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected:
                              _filterOption == ReviewFilterOption.reported,
                          onSelected: (_) => setState(
                            () => _filterOption = ReviewFilterOption.reported,
                          ),
                          label: const Text('Signalés'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sort Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Résultats: ${filteredReviews.length}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                PopupMenuButton<ReviewSortingOption>(
                  initialValue: _sortOption,
                  onSelected: (option) => setState(() => _sortOption = option),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: ReviewSortingOption.recent,
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Plus récent'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: ReviewSortingOption.rating,
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Note la plus haute'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _sortOption == ReviewSortingOption.recent
                              ? 'Récent'
                              : 'Note',
                          style: textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reviews List
            if (filteredReviews.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun avis',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredReviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final review = filteredReviews[index];
                  final isReported = _reportedReviews.contains(review.id);

                  return _ReviewManagementCard(
                    review: review,
                    isReported: isReported,
                    onSubmitResponse: (response) =>
                        _submitResponse(review, response),
                    onReportReview: () => _reportReview(review),
                  ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.04);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatSmallCard extends StatelessWidget {
  const _StatSmallCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewManagementCard extends StatefulWidget {
  const _ReviewManagementCard({
    required this.review,
    required this.isReported,
    required this.onSubmitResponse,
    required this.onReportReview,
  });

  final ReviewModel review;
  final bool isReported;
  final Function(String) onSubmitResponse;
  final VoidCallback onReportReview;

  @override
  State<_ReviewManagementCard> createState() => _ReviewManagementCardState();
}

class _ReviewManagementCardState extends State<_ReviewManagementCard> {
  late TextEditingController _responseController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = DateFormat(
      'd MMM yyyy',
      'fr_FR',
    ).format(widget.review.createdAt);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.isReported
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Review Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.review.userPhotoUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.review.userName,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (widget.isReported)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.error.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag_rounded,
                                    size: 12,
                                    color: colorScheme.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Signalé',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < widget.review.rating.toInt()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            date,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (widget.review.replies.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${widget.review.replies.length} réponse(s)',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.tertiary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Review Comment
            Text(widget.review.comment, style: textTheme.bodyMedium),

            // Review Photos
            if (widget.review.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: widget.review.photoUrls.map((url) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url, fit: BoxFit.cover),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Threaded Replies
            if (widget.review.replies.isNotEmpty) ...[
              ...widget.review.replies.map((reply) {
                final isOwner = reply.senderRole == 'owner';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOwner
                          ? colorScheme.primaryContainer.withValues(alpha: 0.2)
                          : colorScheme.secondaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOwner
                            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                            : colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isOwner)
                              Icon(Icons.business_rounded, size: 16, color: colorScheme.onPrimaryContainer)
                            else if (reply.senderPhotoUrl != null && reply.senderPhotoUrl!.isNotEmpty)
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: NetworkImage(reply.senderPhotoUrl!),
                              )
                            else
                              Icon(Icons.person_rounded, size: 16, color: colorScheme.onSecondaryContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isOwner 
                                    ? 'Réponse de l\'entreprise' 
                                    : (reply.senderName ?? 'Réponse du client'),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isOwner
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reply.message,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
            ],

            // Always allow response form (to continue thread)
            if (true) ...[
              // Response Form (if no response yet)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isExpanded)
                      InkWell(
                        onTap: () => setState(() => _isExpanded = true),
                        child: Row(
                          children: [
                            Icon(
                              Icons.reply_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Répondre à cet avis',
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      TextField(
                        controller: _responseController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Répondez à cet avis...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() => _isExpanded = false);
                              _responseController.clear();
                            },
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              if (_responseController.text.isNotEmpty) {
                                widget.onSubmitResponse(
                                  _responseController.text,
                                );
                                setState(() {
                                  _isExpanded = false;
                                  _responseController.clear();
                                });
                              }
                            },
                            child: const Text('Publier'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onReportReview,
                    icon: const Icon(Icons.flag_rounded),
                    label: const Text('Signaler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(
                        color: colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
