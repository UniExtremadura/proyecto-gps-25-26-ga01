import 'package:equatable/equatable.dart';

class Rating extends Equatable {
  final int id;
  final int userId;
  final String entityType;
  final int entityId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Rating({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as int,
      userId: json['userId'] as int,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'entityType': entityType,
      'entityId': entityId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        entityType,
        entityId,
        rating,
        comment,
        createdAt,
        updatedAt,
      ];
}
