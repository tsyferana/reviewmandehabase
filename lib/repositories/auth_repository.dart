import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  /// Connecte un utilisateur avec son email et son mot de passe
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      // Retourne le message d'erreur spécifique de Supabase (ex: identifiants invalides)
      throw e.message;
    } catch (e) {
      throw 'Une erreur inattendue est survenue lors de la connexion.';
    }
  }

  /// Inscrit un nouvel utilisateur et remplit les métadonnées pour le profil SQL
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String accountType,
  }) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'account_type': accountType,
        },
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Une erreur est survenue lors de l\'inscription.';
    }
  }

  /// Déconnecte l'utilisateur
  Future<void> signOut() async => await _supabase.auth.signOut();

  /// Récupère l'utilisateur actuel s'il est connecté
  User? get currentUser => _supabase.auth.currentUser;

  /// Envoie un e-mail de réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'reviewapp://reset-callback',
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Une erreur est survenue lors de l\'envoi de l\'e-mail.';
    }
  }

  /// Met à jour le mot de passe de l'utilisateur connecté
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Une erreur est survenue lors de la mise à jour du mot de passe.';
    }
  }
}
