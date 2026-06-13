import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../controllers/review_controller.dart';
import '../../models/review_model.dart';
import '../../repositories/review_repository.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    this.businessId = 'biz-001',
  });

  static const routeName = '/business/:id/reviews';

  final String businessId;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final ReviewController _reviewController;

  int? _ratingFilter;
  ReviewSortOption _sortOption = ReviewSortOption.recent;

  @override
  void initState() {
    super.initState();
    _reviewController = ReviewController(ReviewRepository());
    _reviewController.addListener(_onReviewStateChanged);
    unawaited(_reviewController.loadReviews(widget.businessId));
  }

  @override
  void dispose() {
    _reviewController
      ..removeListener(_onReviewStateChanged)
      ..dispose();
    super.dispose();
  }

  void _onReviewStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openReviewForm([ReviewModel? review]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _ReviewFormSheet(
          businessId: widget.businessId,
          review: review,
          isSaving: _reviewController.isSaving,
          onSubmit: ({
            required rating,
            required comment,
            required photoUrls,
          }) async {
            if (review == null) {
              await _reviewController.addReview(
                businessId: widget.businessId,
                rating: rating,
                comment: comment,
                photoUrls: photoUrls,
              );
            } else {
              await _reviewController.updateReview(
                reviewId: review.id,
                rating: rating,
                comment: comment,
                photoUrls: photoUrls,
              );
            }
          },
        ).animate().slideY(
              begin: 0.08,
              end: 0,
              duration: 260.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  Future<void> _confirmDelete(ReviewModel review) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline_rounded),
          title: const Text('Supprimer cet avis ?'),
          content: const Text(
            'Cette action retirera votre avis de la liste mockee.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _reviewController.deleteReview(review.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avis supprime.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _reviewController.filteredReviews(
      ratingFilter: _ratingFilter,
      sortOption: _sortOption,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avis'),
        actions: [
          TextButton.icon(
            onPressed: () => _openReviewForm(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _ReviewFilters(
            ratingFilter: _ratingFilter,
            sortOption: _sortOption,
            onRatingChanged: (value) {
              setState(() => _ratingFilter = value);
            },
            onSortChanged: (value) {
              setState(() => _sortOption = value);
            },
          ),
          Expanded(
            child: _reviewController.isLoading
                ? const Center(child: CircularProgressIndicator())
                : reviews.isEmpty
                    ? const _EmptyReviewsState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: reviews.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return _ReviewCard(
                            review: review,
                            onEdit: review.isCurrentUser
                                ? () => _openReviewForm(review)
                                : null,
                            onDelete: review.isCurrentUser
                                ? () => _confirmDelete(review)
                                : null,
                          ).animate(delay: (index * 45).ms).fadeIn().slideY(
                                begin: 0.04,
                                end: 0,
                              );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReviewForm(),
        icon: const Icon(Icons.rate_review_rounded),
        label: const Text('Publier un avis'),
      ),
    );
  }
}

class _ReviewFilters extends StatelessWidget {
  const _ReviewFilters({
    required this.ratingFilter,
    required this.sortOption,
    required this.onRatingChanged,
    required this.onSortChanged,
  });

  final int? ratingFilter;
  final ReviewSortOption sortOption;
  final ValueChanged<int?> onRatingChanged;
  final ValueChanged<ReviewSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                FilterChip(
                  selected: ratingFilter == null,
                  label: const Text('Toutes'),
                  onSelected: (_) => onRatingChanged(null),
                ),
                const SizedBox(width: 8),
                for (var rating = 5; rating >= 1; rating--) ...[
                  FilterChip(
                    selected: ratingFilter == rating,
                    label: Text('$rating etoiles'),
                    avatar: const Icon(Icons.star_rounded),
                    onSelected: (_) => onRatingChanged(rating),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.sort_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<ReviewSortOption>(
                    selected: {sortOption},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      onSortChanged(selection.first);
                    },
                    segments: const [
                      ButtonSegment(
                        value: ReviewSortOption.recent,
                        label: Text('Recent'),
                      ),
                      ButtonSegment(
                        value: ReviewSortOption.relevant,
                        label: Text('Pertinent'),
                      ),
                      ButtonSegment(
                        value: ReviewSortOption.rating,
                        label: Text('Note'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.onEdit,
    required this.onDelete,
  });

  final ReviewModel review;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = DateFormat('d MMM yyyy', 'fr_FR').format(review.createdAt);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(review.userPhotoUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        date,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (review.isCurrentUser)
                  PopupMenuButton<String>(
                    tooltip: 'Actions',
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      }
                      if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifier'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InteractiveStars(
              rating: review.rating,
              onChanged: null,
              size: 21,
            ),
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            if (review.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photoUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        review.photoUrls[index],
                        width: 110,
                        height: 82,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewFormSheet extends StatefulWidget {
  const _ReviewFormSheet({
    required this.businessId,
    required this.review,
    required this.isSaving,
    required this.onSubmit,
  });

  final String businessId;
  final ReviewModel? review;
  final bool isSaving;
  final Future<void> Function({
    required double rating,
    required String comment,
    required List<String> photoUrls,
  }) onSubmit;

  @override
  State<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<_ReviewFormSheet> {
  static const _mockPhotoPool = [
    'https://picsum.photos/seed/new-review-1/320/240',
    'https://picsum.photos/seed/new-review-2/320/240',
    'https://picsum.photos/seed/new-review-3/320/240',
    'https://picsum.photos/seed/new-review-4/320/240',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _commentController;
  late double _rating;
  late List<String> _photoUrls;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(
      text: widget.review?.comment ?? '',
    );
    _rating = widget.review?.rating ?? 0;
    _photoUrls = [...?widget.review?.photoUrls];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectionnez une note.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await widget.onSubmit(
      rating: _rating,
      comment: _commentController.text,
      photoUrls: _photoUrls,
    );

    if (!mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.review == null ? 'Avis publie.' : 'Avis mis a jour.',
        ),
      ),
    );
  }

  void _addMockPhoto() {
    final nextPhoto = _mockPhotoPool[_photoUrls.length % _mockPhotoPool.length];
    setState(() => _photoUrls = [..._photoUrls, nextPhoto]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.review == null ? 'Laisser un avis' : 'Modifier l’avis',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 18),
              Center(
                child: _InteractiveStars(
                  rating: _rating,
                  size: 34,
                  onChanged: (rating) {
                    setState(() => _rating = rating);
                  },
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _commentController,
                minLines: 4,
                maxLines: 7,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Votre commentaire',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 12) {
                    return 'Ajoutez un commentaire d’au moins 12 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Photos',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addMockPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              if (_photoUrls.isEmpty)
                Container(
                  height: 86,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Aucune photo ajoutee'),
                )
              else
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photoUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _photoUrls[index],
                              width: 116,
                              height: 92,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setState(() => _photoUrls.removeAt(index));
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _isSaving || widget.isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: _isSaving || widget.isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(widget.review == null ? 'Publier' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveStars extends StatelessWidget {
  const _InteractiveStars({
    required this.rating,
    required this.onChanged,
    this.size = 28,
  });

  final double rating;
  final ValueChanged<double>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1.0;
        final icon = rating >= value
            ? Icons.star_rounded
            : Icons.star_border_rounded;

        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: '$value etoiles',
          onPressed: onChanged == null ? null : () => onChanged!(value),
          icon: Icon(
            icon,
            color: colorScheme.tertiary,
            size: size,
          ),
        );
      }),
    );
  }
}

class _EmptyReviewsState extends StatelessWidget {
  const _EmptyReviewsState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rate_review_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Aucun avis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Modifiez les filtres ou publiez le premier avis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
