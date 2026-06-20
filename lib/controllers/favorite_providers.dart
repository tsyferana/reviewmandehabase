import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../repositories/favorite_repository.dart';
import 'favorite_controller.dart';

/// Fournit l'instance unique du repository des favoris
final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository();
});

/// Fournit l'état et la logique du contrôleur des favoris
final favoriteControllerProvider = ChangeNotifierProvider<FavoriteController>((ref) {
  final repository = ref.watch(favoriteRepositoryProvider);
  return FavoriteController(repository);
});
