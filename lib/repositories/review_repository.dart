import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final _supabase = Supabase.instance.client;

  Future<void> _updateBusinessStats(String businessId) async {
    final response = await _supabase.from('reviews').select('rating').eq('business_id', businessId);
    final ratings = (response as List).map((e) => e['rating'] as num).toList();
    
    final reviewCount = ratings.length;
    final avgRating = reviewCount > 0 
        ? ratings.reduce((a, b) => a + b) / reviewCount 
        : 0.0;

    await _supabase.from('businesses').update({
      'rating': avgRating,
      'review_count': reviewCount,
    }).eq('id', businessId);
  }

  Future<List<ReviewModel>> getReviewsForBusiness(String businessId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final response = await _supabase.from('reviews')
        .select('*, profiles(full_name, avatar_url)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
        
    return response.map((e) => ReviewModel.fromJson(e, currentUserId: currentUserId)).toList();
  }

  Future<ReviewModel> addReview({
    required String businessId,
    required double rating,
    required String comment,
    required List<String> photoUrls,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw 'Utilisateur non connecté';

    final response = await _supabase.from('reviews').insert({
      'business_id': businessId,
      'user_id': currentUserId,
      'rating': rating,
      'comment': comment.trim(),
      'photo_urls': photoUrls,
    }).select('*, profiles(full_name, avatar_url)').single();

    await _updateBusinessStats(businessId);

    return ReviewModel.fromJson(response, currentUserId: currentUserId);
  }

  Future<ReviewModel> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
    required List<String> photoUrls,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    
    final response = await _supabase.from('reviews').update({
      'rating': rating,
      'comment': comment.trim(),
      'photo_urls': photoUrls,
    }).eq('id', reviewId).select('*, profiles(full_name, avatar_url)').single();

    final businessId = response['business_id'] as String;
    await _updateBusinessStats(businessId);

    return ReviewModel.fromJson(response, currentUserId: currentUserId);
  }

  Future<void> deleteReview(String reviewId) async {
    final reviewResponse = await _supabase.from('reviews').select('business_id').eq('id', reviewId).single();
    final businessId = reviewResponse['business_id'] as String;
    
    await _supabase.from('reviews').delete().eq('id', reviewId);
    
    await _updateBusinessStats(businessId);
  }
}
