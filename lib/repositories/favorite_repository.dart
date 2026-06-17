import '../models/business_model.dart';
import '../services/supabase_data_service.dart';

class FavoriteRepository {
  FavoriteRepository({SupabaseDataService? dataService})
      : _dataService = dataService ?? SupabaseDataService();

  final SupabaseDataService _dataService;

  static final Set<String> _favoriteBusinessIds = {};

  Future<List<BusinessModel>> getFavorites() async {
    final businesses = await _dataService.getBusinesses();

    return businesses
        .where((business) => _favoriteBusinessIds.contains(business.id))
        .toList();
  }

  Future<void> removeFavorite(String businessId) async {
    _favoriteBusinessIds.remove(businessId);
  }

  Future<void> addFavorite(String businessId) async {
    _favoriteBusinessIds.add(businessId);
  }
}
