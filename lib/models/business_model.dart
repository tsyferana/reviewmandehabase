class BusinessModel {
  const BusinessModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.city,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.isPopular,
    this.latitude = -18.8792,
    this.longitude = 47.5079,
    this.isOpen = true,
    this.address = 'Analakely, Antananarivo',
    this.description =
        'Une adresse locale appreciee pour son accueil, la qualite du service et son ambiance soignee.',
    this.phone = '+261 34 00 000 00',
    this.galleryUrls = const [],
    this.openingHours = const {},
    this.services = const {},
  });

  final String id;
  final String name;
  final String categoryId;
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
  final List<String> galleryUrls;
  final Map<String, String> openingHours;
  final Map<String, String> services;

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      city: json['city'] as String,
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      isPopular: json['isPopular'] as bool,
      latitude: (json['latitude'] as num? ?? -18.8792).toDouble(),
      longitude: (json['longitude'] as num? ?? 47.5079).toDouble(),
      isOpen: json['isOpen'] as bool? ?? true,
      address: json['address'] as String? ?? 'Analakely, Antananarivo',
      description: json['description'] as String? ??
          'Une adresse locale appreciee pour son accueil, la qualite du service et son ambiance soignee.',
      phone: json['phone'] as String? ?? '+261 34 00 000 00',
      galleryUrls: List<String>.from(json['galleryUrls'] as List? ?? []),
      openingHours: Map<String, String>.from(json['openingHours'] as Map? ?? {}),
      services: Map<String, String>.from(json['services'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'city': city,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'distanceKm': distanceKm,
      'isPopular': isPopular,
      'latitude': latitude,
      'longitude': longitude,
      'isOpen': isOpen,
      'address': address,
      'description': description,
      'phone': phone,
      'galleryUrls': galleryUrls,
      'openingHours': openingHours,
      'services': services,
    };
  }
}
