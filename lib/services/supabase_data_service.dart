import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/business_model.dart';
import '../models/category_model.dart';
import '../models/review_model.dart';
import 'location_sim_service.dart';

class SupabaseDataService {
  final _supabase = Supabase.instance.client;
  final _locationService = LocationSimService();

  Future<List<CategoryModel>> getCategories() async {
    final response = await _supabase.from('categories').select();
    return response.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<List<BusinessModel>> getBusinesses() async {
    final response = await _supabase.from('businesses').select('*, categories(name)').eq('status', 'approved');
    
    final businessIds = response.map((e) => e['id'] as String).toList();
    if (businessIds.isNotEmpty) {
      try {
        final reviewsResponse = await _supabase.from('reviews').select('business_id, rating').inFilter('business_id', businessIds);
        final reviewsMap = <String, List<num>>{};
        for (var r in reviewsResponse) {
          reviewsMap.putIfAbsent(r['business_id'] as String, () => []).add(r['rating'] as num);
        }
        for (var biz in response) {
          final bizReviews = reviewsMap[biz['id'] as String] ?? [];
          final reviewCount = bizReviews.length;
          biz['rating'] = reviewCount > 0 ? bizReviews.reduce((a, b) => a + b) / reviewCount : 0.0;
          biz['review_count'] = reviewCount;
        }
      } catch (e) {
        debugPrint('Fallback rating fetch failed: $e');
      }
    }

    final businesses = response.map((e) => BusinessModel.fromJson(e)).toList();

    try {
      final userLoc = await _locationService.getCurrentLocation();
      final userLatLng = LatLng(userLoc.latitude, userLoc.longitude);
      const distanceCalc = Distance();
      
      return businesses.map((business) {
        final bizLatLng = LatLng(business.latitude, business.longitude);
        final distInMeters = distanceCalc.distance(userLatLng, bizLatLng);
        return business.copyWith(distanceKm: distInMeters / 1000.0);
      }).toList();
    } catch (_) {
      return businesses;
    }
  }

  Future<BusinessModel?> getBusinessById(String id) async {
    final response = await _supabase.from('businesses').select('*, categories(name)').eq('id', id).maybeSingle();
    if (response == null) return null;
    
    try {
      final reviewsResponse = await _supabase.from('reviews').select('rating').eq('business_id', id);
      final reviewCount = reviewsResponse.length;
      response['rating'] = reviewCount > 0 ? reviewsResponse.map((r) => r['rating'] as num).reduce((a, b) => a + b) / reviewCount : 0.0;
      response['review_count'] = reviewCount;
    } catch (e) {
      debugPrint('Fallback rating fetch failed: $e');
    }
    
    var business = BusinessModel.fromJson(response);
    
    try {
      final userLoc = await _locationService.getCurrentLocation();
      final userLatLng = LatLng(userLoc.latitude, userLoc.longitude);
      final bizLatLng = LatLng(business.latitude, business.longitude);
      final distInMeters = const Distance().distance(userLatLng, bizLatLng);
      business = business.copyWith(distanceKm: distInMeters / 1000.0);
    } catch (_) {}
    
    return business;
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

    final name = file.name as String;
    final ext = name.split('.').last.toLowerCase();
    final path = '${user.id}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    
    final bytes = await file.readAsBytes();
    await _supabase.storage.from('businesses').uploadBinary(
      path, 
      bytes,
      fileOptions: FileOptions(contentType: 'image/$ext'),
    );
    return _supabase.storage.from('businesses').getPublicUrl(path);
  }

  Future<String> uploadReviewImage(dynamic file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Utilisateur non connecté.';

    final name = file.name as String;
    final ext = name.split('.').last.toLowerCase();
    final path = '${user.id}/review_${DateTime.now().millisecondsSinceEpoch}.$ext';
    
    final bytes = await file.readAsBytes();
    await _supabase.storage.from('businesses').uploadBinary(
      path, 
      bytes,
      fileOptions: FileOptions(contentType: 'image/$ext'),
    );
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
      final biz = response.first as Map<String, dynamic>;
      try {
        final reviewsResponse = await _supabase.from('reviews').select('rating').eq('business_id', biz['id']);
        final reviewCount = reviewsResponse.length;
        biz['rating'] = reviewCount > 0 ? reviewsResponse.map((r) => r['rating'] as num).reduce((a, b) => a + b) / reviewCount : 0.0;
        biz['review_count'] = reviewCount;
      } catch (e) {
        debugPrint('Fallback rating fetch failed: $e');
      }
      return biz;
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

  Future<List<Map<String, dynamic>>> getBusinessViews(String businessId) async {
    return await _supabase
        .from('business_views')
        .select('*')
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
  }

  Future<void> updateAccountType(String type) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.auth.updateUser(UserAttributes(data: {'account_type': type}));
    await _supabase.from('profiles').update({'account_type': type}).eq('id', user.id);
  }

  Future<void> recordBusinessView(String businessId) async {
    final user = _supabase.auth.currentUser;
    await _supabase.from('business_views').insert({
      'business_id': businessId,
      if (user != null) 'user_id': user.id,
    });
  }

  // ================= CLIENT REPORTS =================

  Future<void> createReport(String reviewId, String reportType, String reason) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Non authentifié');
    
    await _supabase.from('reports').insert({
      'review_id': reviewId,
      'reporter_id': user.id,
      'report_type': reportType,
      'reason': reason,
    });
  }

  // ================= ADMIN METHODS =================

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final usersResp = await _supabase.from('profiles').select('id');
    final bizResp = await _supabase.from('businesses').select('id, status, categories(name)');
    final reviewsResp = await _supabase.from('reviews').select('id');
    final reportsResp = await _supabase.from('reports').select('id, status');

    int pendingBiz = bizResp.where((b) => b['status'] == 'pending').length;
    int pendingReports = reportsResp.where((r) => r['status'] == 'pending').length;

    Map<String, int> categoryCounts = {};
    for (var b in bizResp) {
      final cat = b['categories'];
      String catName = 'Autres';
      if (cat != null && cat is Map && cat['name'] != null) {
        catName = cat['name'] as String;
      }
      categoryCounts[catName] = (categoryCounts[catName] ?? 0) + 1;
    }

    // Si la map est vide, on met quelques catégories à 0 pour l'affichage
    if (categoryCounts.isEmpty) {
      categoryCounts = {'Restaurants': 0, 'Hôtels': 0, 'Boutiques': 0, 'Services': 0, 'Autres': 0};
    }

    return {
      'users': usersResp.length,
      'businesses': bizResp.length,
      'reviews': reviewsResp.length,
      'pendingReports': pendingReports,
      'pendingApprovals': pendingBiz,
      'businessByCategory': categoryCounts,
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

  Future<List<Map<String, dynamic>>> getUserReviews() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    
    final reviewsData = await _supabase.from('reviews')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
        
    final List<Map<String, dynamic>> enrichedReviews = [];
    for (var review in reviewsData) {
      final mutableReview = Map<String, dynamic>.from(review);
      if (mutableReview['business_id'] != null) {
        try {
          mutableReview['businesses'] = await _supabase
              .from('businesses')
              .select('id, name, image_url')
              .eq('id', mutableReview['business_id'])
              .maybeSingle();
        } catch (e) {
          debugPrint('Error fetching business for review: $e');
        }
      }
      enrichedReviews.add(mutableReview);
    }
    
    return enrichedReviews;
  }

  Future<void> createAdminNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
    });
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

  // ================= ADMIN REPORTS =================

  Future<List<Map<String, dynamic>>> getAllReportsAdmin() async {
    final reportsData = await _supabase.from('reports').select().order('created_at', ascending: false);
    
    final List<Map<String, dynamic>> enrichedReports = [];
    for (var report in reportsData) {
      final mutableReport = Map<String, dynamic>.from(report);
      
      try {
        final reviewData = await _supabase
            .from('reviews')
            .select()
            .eq('id', report['review_id'])
            .maybeSingle();
            
        if (reviewData != null) {
          final mutableReview = Map<String, dynamic>.from(reviewData);
          
          if (mutableReview['user_id'] != null) {
            mutableReview['profiles'] = await _supabase
                .from('profiles')
                .select('full_name, avatar_url')
                .eq('id', mutableReview['user_id'])
                .maybeSingle();
          }
          
          if (mutableReview['business_id'] != null) {
            mutableReview['businesses'] = await _supabase
                .from('businesses')
                .select('name, image_url')
                .eq('id', mutableReview['business_id'])
                .maybeSingle();
          }
          
          mutableReport['reviews'] = mutableReview;
        }

        mutableReport['profiles'] = await _supabase
            .from('profiles')
            .select('full_name, avatar_url, email')
            .eq('id', report['reporter_id'])
            .maybeSingle();

        enrichedReports.add(mutableReport);
      } catch (e) {
        // Continue if a single report fails to enrich to avoid breaking the whole list
        print('Error enriching report: $e');
        enrichedReports.add(mutableReport);
      }
    }
    
    return enrichedReports;
  }

  Future<void> updateReportStatusAdmin(String reportId, String status) async {
    await _supabase.from('reports').update({'status': status}).eq('id', reportId);
  }

  Future<void> deleteReviewAdmin(String reviewId) async {
    await _supabase.from('reviews').delete().eq('id', reviewId);
  }
}
