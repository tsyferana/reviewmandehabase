class BusinessModel {
  const BusinessModel({
    required this.id,
    required this.name,
    this.ownerId,
    this.categoryId,
    this.categoryName = '',
    this.city = 'Antananarivo',
    this.imageUrl = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.distanceKm = 0.0,
    this.isPopular = false,
    this.latitude = -18.8792,
    this.longitude = 47.5079,
    this.isOpen = true,
    this.address = '',
    this.description = '',
    this.phone = '',
    this.email,
    this.galleryUrls = const [],
    this.openingHours = const {},
    this.services = const {},
  });

  final String id;
  final String name;
  final String? ownerId;
  final String? categoryId;
  final String categoryName;
  final String city;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final bool isPopular;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final String address;
  final String description;
  final String phone;
  final String? email;
  final List<String> galleryUrls;
  final Map<String, dynamic> openingHours;
  final dynamic services;

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['categories'] != null ? json['categories']['name'] as String : '',
      city: json['city'] as String? ?? 'Antananarivo',
      imageUrl: json['image_url'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      isPopular: json['is_popular'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble() ?? -18.8792,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 47.5079,
      isOpen: json['is_open'] as bool? ?? true,
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      galleryUrls: List<String>.from(json['gallery_urls'] as List? ?? []),
      openingHours: json['opening_hours'] is Map ? Map<String, dynamic>.from(json['opening_hours'] as Map) : {},
      services: json['services'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'category_id': categoryId,
      'city': city,
      'image_url': imageUrl,
      'rating': rating,
      'review_count': reviewCount,
      'distance_km': distanceKm,
      'is_popular': isPopular,
      'latitude': latitude,
      'longitude': longitude,
      'is_open': isOpen,
      'address': address,
      'description': description,
      'phone': phone,
      'email': email,
      'gallery_urls': galleryUrls,
      'opening_hours': openingHours,
      'services': services,
    };
  }
}
