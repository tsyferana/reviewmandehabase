import 'package:flutter/foundation.dart';

import '../models/business_model.dart';
import '../repositories/favorite_repository.dart';

class FavoriteController extends ChangeNotifier {
  FavoriteController(this._favoriteRepository);

  final FavoriteRepository _favoriteRepository;

  bool _isLoading = false;
  List<BusinessModel> _favorites = [];

  bool get isLoading => _isLoading;
  List<BusinessModel> get favorites => List.unmodifiable(_favorites);

  Future<void> loadFavorites() async {
    _setLoading(true);
    _favorites = await _favoriteRepository.getFavorites();
    _setLoading(false);
  }

  Future<void> refresh() => loadFavorites();

  Future<void> removeFavorite(String businessId) async {
    final previousFavorites = [..._favorites];
    _favorites.removeWhere((business) => business.id == businessId);
    notifyListeners();

    try {
      await _favoriteRepository.removeFavorite(businessId);
    } catch (_) {
      _favorites = previousFavorites;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
