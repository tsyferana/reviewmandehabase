import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final _supabase = Supabase.instance.client;

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

    return ReviewModel.fromJson(response, currentUserId: currentUserId);
  }

  Future<void> deleteReview(String reviewId) async {
    await _supabase.from('reviews').delete().eq('id', reviewId);
  }
}
