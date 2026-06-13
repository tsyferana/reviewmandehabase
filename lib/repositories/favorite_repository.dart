import '../models/business_model.dart';
import '../services/mock_data_service.dart';

class FavoriteRepository {
  FavoriteRepository({MockDataService? mockDataService})
      : _mockDataService = mockDataService ?? MockDataService();

  final MockDataService _mockDataService;

  static final Set<String> _favoriteBusinessIds = {
    'biz-001',
    'biz-003',
    'biz-005',
    'biz-008',
  };

  Future<List<BusinessModel>> getFavorites() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final businesses = await _mockDataService.getBusinesses();

    return businesses
        .where((business) => _favoriteBusinessIds.contains(business.id))
        .toList();
  }

  Future<void> removeFavorite(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    _favoriteBusinessIds.remove(businessId);
  }

  Future<void> addFavorite(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    _favoriteBusinessIds.add(businessId);
  }
}
