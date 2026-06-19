class ReviewReplyModel {
  const ReviewReplyModel({
    required this.senderRole,
    this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    required this.message,
    required this.createdAt,
  });

  final String senderRole; // 'owner' or 'client'
  final String? senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final String message;
  final DateTime createdAt;

  factory ReviewReplyModel.fromJson(Map<String, dynamic> json) {
    return ReviewReplyModel(
      senderRole: json['senderRole']?.toString() ?? 'owner',
      senderId: json['senderId']?.toString(),
      senderName: json['senderName']?.toString(),
      senderPhotoUrl: json['senderPhotoUrl']?.toString(),
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderRole': senderRole,
      if (senderId != null) 'senderId': senderId,
      if (senderName != null) 'senderName': senderName,
      if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

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
    this.replies = const [],
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
  final List<ReviewReplyModel> replies;
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
    List<ReviewReplyModel>? replies,
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
      replies: replies ?? this.replies,
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
      userName: profile['full_name']?.toString() ?? 'Utilisateur',
      userPhotoUrl: profile['avatar_url']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment']?.toString() ?? '',
      photoUrls: (json['photo_urls'] as List?)?.map((e) {
        if (e is String) return e;
        if (e is Map) return e.values.firstOrNull?.toString() ?? e.toString();
        return e.toString();
      }).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      replies: (json['replies'] as List?)?.map((e) => ReviewReplyModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
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
      'replies': replies.map((e) => e.toJson()).toList(),
    };
  }
}
