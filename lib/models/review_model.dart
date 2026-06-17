class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.photoUrls,
    required this.createdAt,
    this.isCurrentUser = false,
  });

  final String id;
  final String businessId;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final double rating;
  final String comment;
  final List<String> photoUrls;
  final DateTime createdAt;
  final bool isCurrentUser;

  ReviewModel copyWith({
    String? id,
    String? businessId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    double? rating,
    String? comment,
    List<String>? photoUrls,
    DateTime? createdAt,
    bool? isCurrentUser,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};
    final uId = json['user_id'] as String? ?? '';
    return ReviewModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String? ?? '',
      userId: uId,
      userName: profile['full_name'] as String? ?? 'Utilisateur',
      userPhotoUrl: profile['avatar_url'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      photoUrls: List<String>.from(json['photo_urls'] as List? ?? []),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      isCurrentUser: currentUserId != null && currentUserId == uId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'photo_urls': photoUrls,
    };
  }
}
