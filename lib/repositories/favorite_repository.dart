import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_model.dart';
import '../services/supabase_data_service.dart';

class FavoriteRepository {
  FavoriteRepository({SupabaseDataService? dataService})
      : _dataService = dataService ?? SupabaseDataService();

  final SupabaseDataService _dataService;
  final _supabase = Supabase.instance.client;

  Future<List<BusinessModel>> getFavorites() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('favorites')
        .select('business_id')
        .eq('user_id', currentUserId);

    if (response.isEmpty) return [];

    final businessIds = response.map((row) => row['business_id'] as String).toList();

    final businessesResponse = await _supabase
        .from('businesses')
        .select('*, categories(name)')
        .inFilter('id', businessIds);
        
    return businessesResponse.map((e) => BusinessModel.fromJson(e)).toList();
  }

  Future<void> removeFavorite(String businessId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw 'Vous devez être connecté pour retirer un favori.';

    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', currentUserId)
        .eq('business_id', businessId);
  }

  Future<void> addFavorite(String businessId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw 'Vous devez être connecté pour ajouter un favori.';

    // Insert but ignore if already exists (to avoid unique constraint errors if clicked twice)
    try {
      await _supabase.from('favorites').insert({
        'user_id': currentUserId,
        'business_id': businessId,
      });
    } catch (e) {
      // Ignore if it's a unique constraint violation
      // It means it's already favorited
    }
  }

  Future<bool> isFavorite(String businessId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final response = await _supabase
        .from('favorites')
        .select('id')
        .eq('user_id', currentUserId)
        .eq('business_id', businessId)
        .maybeSingle();

    return response != null;
  }
}
