import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  /// Connecte un utilisateur via Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      final androidClientId = dotenv.env['GOOGLE_ANDROID_CLIENT_ID'];
      
      if (webClientId == null || androidClientId == null) {
        throw 'Configuration Google non trouvée.';
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Connexion Google annulée par l\'utilisateur.';
      }
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'Jeton d\'accès (Access Token) introuvable.';
      }
      
      if (idToken == null) {
        throw 'Jeton d\'identification (ID Token) introuvable.';
      }

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Erreur Google: $e';
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
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'account_type': accountType,
        },
      );

      if (response.user != null) {
        await _supabase.from('profiles').upsert({
          'id': response.user!.id,
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'account_type': accountType,
        });
      }

      return response;
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

  /// Met à jour le profil (nom et/ou photo)
  Future<void> updateProfile({
    required String fullName,
    File? imageFile,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté.';

      String? publicImageUrl;

      if (imageFile != null) {
        final extension = imageFile.path.split('.').last.toLowerCase();
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final filePath = '${user.id}/$fileName';

        try {
          // Essayer de lister et supprimer les anciennes images pour ne pas encombrer le bucket
          final oldFiles = await _supabase.storage.from('avatars').list(path: user.id);
          if (oldFiles.isNotEmpty) {
            final filesToDelete = oldFiles.map((f) => '${user.id}/${f.name}').toList();
            await _supabase.storage.from('avatars').remove(filesToDelete);
          }
        } catch (_) {
          // Si on n'a pas les permissions pour lister/supprimer, on ignore silencieusement
        }

        // On upload la nouvelle image (avec un nom unique, donc pas besoin d'upsert)
        await _supabase.storage.from('avatars').upload(
          filePath,
          imageFile,
        );

        publicImageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      }

      final data = <String, dynamic>{
        'full_name': fullName,
      };
      if (publicImageUrl != null) {
        data['avatar_url'] = publicImageUrl;
      }

      await _supabase.auth.updateUser(UserAttributes(data: data));
      
      // Upsert into profiles to keep it in sync
      await _supabase.from('profiles').upsert({
         'id': user.id,
         'full_name': fullName,
         'email': user.email,
         if (publicImageUrl != null) 'avatar_url': publicImageUrl,
      });
    } on StorageException catch (e) {
      throw 'Erreur lors de l\'envoi de l\'image : ${e.message}';
    } on AuthException catch (e) {
      throw 'Erreur lors de la mise à jour : ${e.message}';
    } catch (e) {
      throw 'Détail erreur: $e';
    }
  }
}
