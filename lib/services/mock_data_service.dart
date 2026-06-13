import 'package:flutter/material.dart';

import '../models/business_model.dart';
import '../models/category_model.dart';
import '../models/review_model.dart';

class MockDataService {
  Future<List<CategoryModel>> getCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _categories;
  }

  Future<List<BusinessModel>> getBusinesses() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return _businesses;
  }

  Future<BusinessModel?> getBusinessById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    for (final business in _businesses) {
      if (business.id == id) {
        return business;
      }
    }
    return null;
  }

  Future<List<ReviewModel>> getReviewsForBusiness(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _reviews
        .where((review) => review.businessId == businessId)
        .take(4)
        .toList();
  }

  Future<int> getUnreadNotificationsCount() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return 7;
  }

  static final List<CategoryModel> _categories = [
    CategoryModel(
      id: 'restaurants',
      name: 'Restaurants',
      iconCodePoint: Icons.restaurant_rounded.codePoint,
    ),
    CategoryModel(
      id: 'hotels',
      name: 'Hotels',
      iconCodePoint: Icons.hotel_rounded.codePoint,
    ),
    CategoryModel(
      id: 'cafes',
      name: 'Cafes',
      iconCodePoint: Icons.local_cafe_rounded.codePoint,
    ),
    CategoryModel(
      id: 'hair',
      name: 'Coiffeurs',
      iconCodePoint: Icons.content_cut_rounded.codePoint,
    ),
    CategoryModel(
      id: 'garages',
      name: 'Garages',
      iconCodePoint: Icons.car_repair_rounded.codePoint,
    ),
    CategoryModel(
      id: 'pharmacies',
      name: 'Pharmacies',
      iconCodePoint: Icons.local_pharmacy_rounded.codePoint,
    ),
    CategoryModel(
      id: 'clinics',
      name: 'Cliniques',
      iconCodePoint: Icons.local_hospital_rounded.codePoint,
    ),
    CategoryModel(
      id: 'doctors',
      name: 'Medecins',
      iconCodePoint: Icons.medical_services_rounded.codePoint,
    ),
    CategoryModel(
      id: 'electricians',
      name: 'Electriciens',
      iconCodePoint: Icons.electrical_services_rounded.codePoint,
    ),
    CategoryModel(
      id: 'plumbers',
      name: 'Plombiers',
      iconCodePoint: Icons.plumbing_rounded.codePoint,
    ),
    CategoryModel(
      id: 'shops',
      name: 'Boutiques',
      iconCodePoint: Icons.shopping_bag_rounded.codePoint,
    ),
    CategoryModel(
      id: 'schools',
      name: 'Ecoles',
      iconCodePoint: Icons.school_rounded.codePoint,
    ),
    CategoryModel(
      id: 'admin',
      name: 'Services admin',
      iconCodePoint: Icons.account_balance_rounded.codePoint,
    ),
  ];

  static const List<BusinessModel> _businesses = [
    BusinessModel(
      id: 'biz-001',
      name: 'La Varangue',
      categoryId: 'restaurants',
      categoryName: 'Restaurant',
      city: 'Antananarivo',
      imageUrl: 'https://picsum.photos/seed/reviewapp-restaurant/600/420',
      rating: 4.8,
      reviewCount: 326,
      distanceKm: 1.2,
      isPopular: true,
      latitude: -18.9101,
      longitude: 47.5256,
      address: '17 Rue Printsy Ratsimamanga, Antaninarenina',
      description:
          'Cuisine creative, service attentionne et cadre elegant au centre d’Antananarivo.',
      phone: '+261 20 22 273 97',
      galleryUrls: [
        'https://picsum.photos/seed/varangue-gallery-1/600/420',
        'https://picsum.photos/seed/varangue-gallery-2/600/420',
        'https://picsum.photos/seed/varangue-gallery-3/600/420',
      ],
      openingHours: {
        'Lundi': '11:30 - 22:00',
        'Mardi': '11:30 - 22:00',
        'Mercredi': '11:30 - 22:00',
        'Jeudi': '11:30 - 22:00',
        'Vendredi': '11:30 - 23:00',
        'Samedi': '12:00 - 23:00',
        'Dimanche': 'Ferme',
      },
      services: {
        'Menu degustation': '120 000 Ar',
        'Plat du jour': '42 000 Ar',
        'Reservation privee': 'Sur devis',
      },
    ),
    BusinessModel(
      id: 'biz-002',
      name: 'Hotel Panorama',
      categoryId: 'hotels',
      categoryName: 'Hotel',
      city: 'Antananarivo',
      imageUrl: 'https://picsum.photos/seed/reviewapp-hotel/600/420',
      rating: 4.6,
      reviewCount: 214,
      distanceKm: 2.4,
      isPopular: true,
      latitude: -18.9137,
      longitude: 47.5364,
      isOpen: false,
    ),
    BusinessModel(
      id: 'biz-003',
      name: 'Cafe Analakely',
      categoryId: 'cafes',
      categoryName: 'Cafe',
      city: 'Antananarivo',
      imageUrl: 'https://picsum.photos/seed/reviewapp-cafe/600/420',
      rating: 4.7,
      reviewCount: 189,
      distanceKm: 0.8,
      isPopular: true,
      latitude: -18.9068,
      longitude: 47.5231,
    ),
    BusinessModel(
      id: 'biz-004',
      name: 'Studio Mira Coiffure',
      categoryId: 'hair',
      categoryName: 'Coiffeur',
      city: 'Antananarivo',
      imageUrl: 'https://picsum.photos/seed/reviewapp-hair/600/420',
      rating: 4.9,
      reviewCount: 142,
      distanceKm: 3.1,
      isPopular: false,
      latitude: -18.8924,
      longitude: 47.5205,
    ),
    BusinessModel(
      id: 'biz-005',
      name: 'Pharmacie Tana Sante',
      categoryId: 'pharmacies',
      categoryName: 'Pharmacie',
      city: 'Antananarivo',
      imageUrl: 'https://picsum.photos/seed/reviewapp-pharmacy/600/420',
      rating: 4.5,
      reviewCount: 98,
      distanceKm: 0.5,
      isPopular: true,
      latitude: -18.9059,
      longitude: 47.5224,
    ),
    BusinessModel(
      id: 'biz-006',
      name: 'Garage Ivato Auto',
      categoryId: 'garages',
      categoryName: 'Garage',
      city: 'Antananarivo',
      imageUrl: 'https://picsum.photos/seed/reviewapp-garage/600/420',
      rating: 4.4,
      reviewCount: 77,
      distanceKm: 4.6,
      isPopular: false,
      latitude: -18.8366,
      longitude: 47.4791,
      isOpen: false,
    ),
    BusinessModel(
      id: 'biz-007',
      name: 'Clinique Saint Michel',
      categoryId: 'clinics',
      categoryName: 'Clinique',
      city: 'Antananarivo',
      imageUrl: 'https://picsum.photos/seed/reviewapp-clinic/600/420',
      rating: 4.9,
      reviewCount: 121,
      distanceKm: 1.7,
      isPopular: false,
      latitude: -18.9148,
      longitude: 47.5318,
    ),
    BusinessModel(
      id: 'biz-008',
      name: 'Boutique Lamba',
      categoryId: 'shops',
      categoryName: 'Boutique',
      city: 'Antananarivo',
      imageUrl: 'https://picsum.photos/seed/reviewapp-shop/600/420',
      rating: 4.3,
      reviewCount: 64,
      distanceKm: 2.1,
      isPopular: true,
      latitude: -18.9015,
      longitude: 47.5167,
    ),
  ];

  static final List<ReviewModel> _reviews = [
    ReviewModel(
      id: 'review-001',
      businessId: 'biz-001',
      userName: 'Miora R.',
      userPhotoUrl: 'https://i.pravatar.cc/120?img=32',
      rating: 5,
      comment:
          'Service impeccable, plats tres bien presentes et equipe vraiment attentive.',
      photoUrls: const [
        'https://picsum.photos/seed/review-varangue-1/320/240',
        'https://picsum.photos/seed/review-varangue-2/320/240',
      ],
      createdAt: DateTime(2026, 6, 8),
    ),
    ReviewModel(
      id: 'review-002',
      businessId: 'biz-001',
      userName: 'Tojo A.',
      userPhotoUrl: 'https://i.pravatar.cc/120?img=12',
      rating: 4.5,
      comment:
          'Tres belle adresse pour un diner calme. Les desserts valent le detour.',
      photoUrls: const [
        'https://picsum.photos/seed/review-varangue-3/320/240',
      ],
      createdAt: DateTime(2026, 6, 2),
    ),
    ReviewModel(
      id: 'review-003',
      businessId: 'biz-001',
      userName: 'Sarah N.',
      userPhotoUrl: 'https://i.pravatar.cc/120?img=47',
      rating: 5,
      comment:
          'Reservation facile, accueil chaleureux et excellente recommandation de menu.',
      photoUrls: const [],
      createdAt: DateTime(2026, 5, 25),
    ),
  ];
}
