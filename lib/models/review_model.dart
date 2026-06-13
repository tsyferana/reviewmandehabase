class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.businessId,
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
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      photoUrls: List<String>.from(json['photoUrls'] as List<dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'photoUrls': photoUrls,
      'createdAt': createdAt.toIso8601String(),
      'isCurrentUser': isCurrentUser,
    };
  }
}
