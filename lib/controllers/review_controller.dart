import 'package:flutter/foundation.dart';

import '../models/review_model.dart';
import '../repositories/review_repository.dart';

enum ReviewSortOption {
  recent,
  relevant,
  rating,
}

class ReviewController extends ChangeNotifier {
  ReviewController(this._reviewRepository);

  final ReviewRepository _reviewRepository;

  bool _isLoading = false;
  bool _isSaving = false;
  List<ReviewModel> _reviews = [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  List<ReviewModel> get reviews => List.unmodifiable(_reviews);

  Future<void> loadReviews(String businessId) async {
    _setLoading(true);
    _reviews = await _reviewRepository.getReviewsForBusiness(businessId);
    _setLoading(false);
  }

  List<ReviewModel> filteredReviews({
    required int? ratingFilter,
    required ReviewSortOption sortOption,
  }) {
    final filtered = _reviews.where((review) {
      if (ratingFilter == null) {
        return true;
      }
      return review.rating.floor() == ratingFilter;
    }).toList();

    switch (sortOption) {
      case ReviewSortOption.recent:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ReviewSortOption.relevant:
        filtered.sort((a, b) {
          final scoreA = a.photoUrls.length + a.comment.length / 100;
          final scoreB = b.photoUrls.length + b.comment.length / 100;
          return scoreB.compareTo(scoreA);
        });
      case ReviewSortOption.rating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return filtered;
  }

  Future<void> addReview({
    required String businessId,
    required double rating,
    required String comment,
    required List<String> photoUrls,
  }) async {
    _setSaving(true);
    final review = await _reviewRepository.addReview(
      businessId: businessId,
      rating: rating,
      comment: comment,
      photoUrls: photoUrls,
    );
    _reviews.insert(0, review);
    _setSaving(false);
  }

  Future<void> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
    required List<String> photoUrls,
  }) async {
    _setSaving(true);
    final updatedReview = await _reviewRepository.updateReview(
      reviewId: reviewId,
      rating: rating,
      comment: comment,
      photoUrls: photoUrls,
    );
    final index = _reviews.indexWhere((review) => review.id == reviewId);
    if (index != -1) {
      _reviews[index] = updatedReview;
    }
    _setSaving(false);
  }

  Future<void> deleteReview(String reviewId) async {
    _setSaving(true);
    await _reviewRepository.deleteReview(reviewId);
    _reviews.removeWhere((review) => review.id == reviewId);
    _setSaving(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }
}
