import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';

/// Fournit l'instance unique du repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Fournit l'état et la logique du contrôleur d'authentification
final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
