import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_model.dart';
import '../models/category_model.dart';
import '../models/review_model.dart';

class SupabaseDataService {
  final _supabase = Supabase.instance.client;

  Future<List<CategoryModel>> getCategories() async {
    final response = await _supabase.from('categories').select();
    return response.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<List<BusinessModel>> getBusinesses() async {
    final response = await _supabase.from('businesses').select('*, categories(name)');
    return response.map((e) => BusinessModel.fromJson(e)).toList();
  }

  Future<BusinessModel?> getBusinessById(String id) async {
    final response = await _supabase.from('businesses').select('*, categories(name)').eq('id', id).maybeSingle();
    if (response == null) return null;
    return BusinessModel.fromJson(response);
  }

  Future<List<ReviewModel>> getReviewsForBusiness(String businessId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final response = await _supabase.from('reviews')
        .select('*, profiles(full_name, avatar_url)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false)
        .limit(10);
    return response.map((e) => ReviewModel.fromJson(e, currentUserId: currentUserId)).toList();
  }

  Future<int> getUnreadNotificationsCount() async {
    return 0; // TODO: Implémenter avec une table notifications
  }

  Future<void> createBusiness({
    required String name,
    required String categoryId,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String phone,
    String? email,
    required Map<String, dynamic> openingHours,
    dynamic logoFile, // File from dart:io
    List<dynamic>? galleryFiles, // List of File
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Utilisateur non connecté.';

    String? logoUrl;
    List<String> galleryUrls = [];

    // 1. Upload logo
    if (logoFile != null) {
      final ext = logoFile.path.split('.').last.toLowerCase();
      final path = '${user.id}/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _supabase.storage.from('businesses').upload(path, logoFile);
      logoUrl = _supabase.storage.from('businesses').getPublicUrl(path);
    }

    // 2. Upload gallery
    if (galleryFiles != null && galleryFiles.isNotEmpty) {
      for (int i = 0; i < galleryFiles.length; i++) {
        final file = galleryFiles[i];
        final ext = file.path.split('.').last.toLowerCase();
        final path = '${user.id}/gallery_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
        await _supabase.storage.from('businesses').upload(path, file);
        final url = _supabase.storage.from('businesses').getPublicUrl(path);
        galleryUrls.add(url);
      }
    }

    // 3. Insert into public.businesses
    await _supabase.from('businesses').insert({
      'owner_id': user.id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'image_url': logoUrl,
      'gallery_urls': galleryUrls,
      'opening_hours': openingHours,
      'status': 'pending', // par défaut en attente
    });
  }

  Future<String> uploadBusinessImage(dynamic file, String prefix) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Utilisateur non connecté.';

    final ext = file.path.split('.').last.toLowerCase();
    final path = '${user.id}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _supabase.storage.from('businesses').upload(path, file);
    return _supabase.storage.from('businesses').getPublicUrl(path);
  }

  Future<Map<String, dynamic>?> getUserBusiness() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    // On utilise limit(1) pour éviter l'erreur "multiple rows returned"
    // si l'utilisateur a accidentellement créé plusieurs entreprises.
    final response = await _supabase
        .from('businesses')
        .select('*, categories(name)')
        .eq('owner_id', user.id)
        .limit(1);
        
    if (response.isNotEmpty) {
      return response.first as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> updateBusiness(String businessId, Map<String, dynamic> updates) async {
    await _supabase.from('businesses').update(updates).eq('id', businessId);
  }

  Future<List<Map<String, dynamic>>> getBusinessReviews(String businessId) async {
    return await _supabase
        .from('reviews')
        .select('*, profiles(full_name, avatar_url)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
  }

  Future<void> updateAccountType(String type) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.auth.updateUser(UserAttributes(data: {'account_type': type}));
    await _supabase.from('profiles').update({'account_type': type}).eq('id', user.id);
  }

  // ================= ADMIN METHODS =================

  Future<Map<String, int>> getAdminDashboardStats() async {
    final usersResp = await _supabase.from('profiles').select('id');
    final bizResp = await _supabase.from('businesses').select('id, status');
    final reviewsResp = await _supabase.from('reviews').select('id');
    final reportsResp = await _supabase.from('reports').select('id, status');

    int pendingBiz = bizResp.where((b) => b['status'] == 'pending').length;
    int pendingReports = reportsResp.where((r) => r['status'] == 'pending').length;

    return {
      'users': usersResp.length,
      'businesses': bizResp.length,
      'reviews': reviewsResp.length,
      'pendingReports': pendingReports,
      'pendingApprovals': pendingBiz,
    };
  }

  Future<List<Map<String, dynamic>>> getAllUsersAdmin() async {
    return await _supabase.from('profiles').select().order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getAllBusinessesAdmin() async {
    return await _supabase.from('businesses')
        .select('*, profiles(full_name, email), categories(name)')
        .order('created_at', ascending: false);
  }

  Future<void> updateBusinessStatusAdmin(String businessId, String status) async {
    await _supabase.from('businesses').update({'status': status}).eq('id', businessId);
  }

  Future<void> createCategoryAdmin(String name, String iconName) async {
    await _supabase.from('categories').insert({'name': name, 'icon_name': iconName});
  }

  Future<void> updateCategoryAdmin(String categoryId, String name, String iconName) async {
    await _supabase.from('categories').update({'name': name, 'icon_name': iconName}).eq('id', categoryId);
  }

  Future<void> deleteCategoryAdmin(String categoryId) async {
    await _supabase.from('categories').delete().eq('id', categoryId);
  }

  Future<List<Map<String, dynamic>>> getAllReportsAdmin() async {
    return await _supabase.from('reports')
        .select('*, reviews(*, businesses(name, image_url), profiles(full_name, avatar_url)), profiles(full_name, avatar_url, email)')
        .order('created_at', ascending: false);
  }

  Future<void> updateReportStatusAdmin(String reportId, String status) async {
    await _supabase.from('reports').update({'status': status}).eq('id', reportId);
  }

  Future<void> deleteReviewAdmin(String reviewId) async {
    await _supabase.from('reviews').delete().eq('id', reviewId);
  }
}
