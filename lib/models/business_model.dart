class BusinessModel {
  const BusinessModel({
    required this.id,
    required this.name,
    this.ownerId,
    this.categoryId,
    this.categoryName = '',
    this.city = '',
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
    this.services = const [],
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
  final List<Map<String, String>> services;

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ownerId: json['owner_id']?.toString(),
      categoryId: json['category_id']?.toString(),
      categoryName: json['categories'] != null
          ? json['categories']['name']?.toString() ?? ''
          : '',
      city: json['city']?.toString() ?? 'Antananarivo',
      imageUrl: json['image_url']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      isPopular: json['is_popular'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble() ?? -18.8792,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 47.5079,
      isOpen: json['is_open'] as bool? ?? true,
      address: json['address']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      galleryUrls:
          (json['gallery_urls'] as List?)?.map((e) {
            if (e is String) return e;
            if (e is Map)
              return e.values.firstOrNull?.toString() ?? e.toString();
            return e.toString();
          }).toList() ??
          [],
      openingHours: json['opening_hours'] is Map
          ? Map<String, dynamic>.from(json['opening_hours'] as Map)
          : {},
      services: json['services'] is List
          ? (json['services'] as List).map((e) {
              final m = e as Map;
              return {
                'name': m['name']?.toString() ?? '',
                'price': m['price']?.toString() ?? '',
              };
            }).toList()
          : [],
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

  BusinessModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? categoryId,
    String? categoryName,
    String? city,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    double? distanceKm,
    bool? isPopular,
    double? latitude,
    double? longitude,
    bool? isOpen,
    String? address,
    String? description,
    String? phone,
    String? email,
    List<String>? galleryUrls,
    Map<String, dynamic>? openingHours,
    List<Map<String, String>>? services,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      distanceKm: distanceKm ?? this.distanceKm,
      isPopular: isPopular ?? this.isPopular,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOpen: isOpen ?? this.isOpen,
      address: address ?? this.address,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      openingHours: openingHours ?? this.openingHours,
      services: services ?? this.services,
    );
  }
}
