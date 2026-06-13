import '../models/review_model.dart';

class ReviewRepository {
  static final List<ReviewModel> _reviews = [
    ReviewModel(
      id: 'review-current-user',
      businessId: 'biz-001',
      userName: 'Vous',
      userPhotoUrl: 'https://i.pravatar.cc/120?img=5',
      rating: 4,
      comment:
          'Tres bonne experience globale. Service rapide et equipe attentionnee.',
      photoUrls: const [
        'https://picsum.photos/seed/my-review-1/320/240',
      ],
      createdAt: DateTime(2026, 6, 10),
      isCurrentUser: true,
    ),
    ReviewModel(
      id: 'review-001',
      businessId: 'biz-001',
      userName: 'Miora R.',
      userPhotoUrl: 'https://i.pravatar.cc/120?img=32',
      rating: 5,
      comment:
          'Service impeccable, plats tres bien presentes et equipe vraiment attentive.',
      photoUrls: const [
        'https://picsum.photos/seed/review-varangue-1/320/240',
        'https://picsum.photos/seed/review-varangue-2/320/240',
      ],
      createdAt: DateTime(2026, 6, 8),
    ),
    ReviewModel(
      id: 'review-002',
      businessId: 'biz-001',
      userName: 'Tojo A.',
      userPhotoUrl: 'https://i.pravatar.cc/120?img=12',
      rating: 4.5,
      comment:
          'Tres belle adresse pour un diner calme. Les desserts valent le detour.',
      photoUrls: const [
        'https://picsum.photos/seed/review-varangue-3/320/240',
      ],
      createdAt: DateTime(2026, 6, 2),
    ),
    ReviewModel(
      id: 'review-003',
      businessId: 'biz-001',
      userName: 'Sarah N.',
      userPhotoUrl: 'https://i.pravatar.cc/120?img=47',
      rating: 5,
      comment:
          'Reservation facile, accueil chaleureux et excellente recommandation de menu.',
      photoUrls: const [],
      createdAt: DateTime(2026, 5, 25),
    ),
  ];

  Future<List<ReviewModel>> getReviewsForBusiness(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _reviews
        .where((review) => review.businessId == businessId)
        .map((review) => review.copyWith())
        .toList();
  }

  Future<ReviewModel> addReview({
    required String businessId,
    required double rating,
    required String comment,
    required List<String> photoUrls,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final review = ReviewModel(
      id: 'review-${DateTime.now().microsecondsSinceEpoch}',
      businessId: businessId,
      userName: 'Vous',
      userPhotoUrl: 'https://i.pravatar.cc/120?img=5',
      rating: rating,
      comment: comment.trim(),
      photoUrls: photoUrls,
      createdAt: DateTime.now(),
      isCurrentUser: true,
    );

    _reviews.insert(0, review);
    return review;
  }

  Future<ReviewModel> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
    required List<String> photoUrls,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final index = _reviews.indexWhere((review) => review.id == reviewId);
    final updatedReview = _reviews[index].copyWith(
      rating: rating,
      comment: comment.trim(),
      photoUrls: photoUrls,
      createdAt: DateTime.now(),
    );

    _reviews[index] = updatedReview;
    return updatedReview;
  }

  Future<void> deleteReview(String reviewId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _reviews.removeWhere((review) => review.id == reviewId);
  }
}
