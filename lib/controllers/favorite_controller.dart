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
    try {
      _favorites = await _favoriteRepository.getFavorites();
    } catch (e) {
      debugPrint('Erreur getFavorites: $e');
      _favorites = []; // On évite le crash
    } finally {
      _setLoading(false);
    }
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

  Future<void> addFavorite(BusinessModel business) async {
    if (!_favorites.any((b) => b.id == business.id)) {
      _favorites = [..._favorites, business];
      notifyListeners();

      try {
        await _favoriteRepository.addFavorite(business.id);
      } catch (_) {
        _favorites.removeWhere((b) => b.id == business.id);
        notifyListeners();
      }
    }
  }

  Future<bool> isFavorite(String businessId) async {
    return await _favoriteRepository.isFavorite(businessId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
