class NotificationModel {
  final int id;
  final int userId;
  final String type; // Coincide con NotificationType de Java
  final String title;
  final String message;
  final int? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime sentAt;
  final DateTime createdAt;
  final dynamic metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.referenceId,
    this.referenceType,
    required this.isRead,
    required this.sentAt,
    required this.createdAt,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      title: json['title'],
      message: json['message'] ?? '',
      referenceId: json['referenceId'],
      referenceType: json['referenceType'],
      isRead: json['isRead'] ?? false,
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      metadata: json['metadata'],
    );
  }
}
