import 'package:flutter/foundation.dart';
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

    // Les statistiques (rating et review_count) de l'entreprise sont
    // automatiquement mises à jour par un trigger sur Supabase !

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

    // Les statistiques de l'entreprise sont mises à jour par un trigger sur Supabase !

    return ReviewModel.fromJson(response, currentUserId: currentUserId);
  }

  Future<void> deleteReview(String reviewId) async {
    final reviewResponse = await _supabase.from('reviews').select('business_id').eq('id', reviewId).single();
    final businessId = reviewResponse['business_id'] as String;
    
    await _supabase.from('reviews').delete().eq('id', reviewId);
    
    // La mise à jour des stats est gérée par le trigger Supabase
  }

  Future<ReviewModel> updateReplies(String reviewId, List<ReviewReplyModel> replies) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final repliesJson = replies.map((e) => e.toJson()).toList();
    
    final response = await _supabase.from('reviews').update({
      'replies': repliesJson,
    }).eq('id', reviewId).select('*, profiles(full_name, avatar_url)').single();

    return ReviewModel.fromJson(response, currentUserId: currentUserId);
  }

  Future<ReviewModel> addReplyToReview(String reviewId, String message, String role) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw 'Utilisateur non connecté';

    // 1. Fetch current user's profile
    final profileResp = await _supabase.from('profiles').select('full_name, avatar_url').eq('id', currentUserId).maybeSingle();
    final senderName = profileResp?['full_name']?.toString() ?? 'Utilisateur';
    final senderPhotoUrl = profileResp?['avatar_url']?.toString() ?? '';

    // 2. Fetch the existing review to get current replies
    final reviewResp = await _supabase.from('reviews').select('replies').eq('id', reviewId).single();
    final currentRepliesJson = reviewResp['replies'] as List<dynamic>? ?? [];
    
    final currentReplies = currentRepliesJson
        .map((e) => ReviewReplyModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // 3. Create new reply
    final newReply = ReviewReplyModel(
      senderRole: role,
      senderId: currentUserId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      message: message,
      createdAt: DateTime.now(),
    );

    // 4. Append and update
    currentReplies.add(newReply);
    
    return updateReplies(reviewId, currentReplies);
  }
}
