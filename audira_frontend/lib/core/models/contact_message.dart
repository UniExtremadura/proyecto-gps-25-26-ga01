import 'contact_status.dart';

class ContactMessage {
  final int id;
  final String name;
  final String email;
  final String subject;
  final String message;
  final int? userId;
  final int? songId;
  final int? albumId;
  final bool isRead;
  final ContactStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    this.userId,
    this.songId,
    this.albumId,
    required this.isRead,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String,
      userId: json['userId'] as int?,
      songId: json['songId'] as int?,
      albumId: json['albumId'] as int?,
      isRead: json['isRead'] as bool? ?? false,
      status: json['status'] != null 
          ? ContactStatus.fromString(json['status'] as String)
          : ContactStatus.pending,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'userId': userId,
      'songId': songId,
      'albumId': albumId,
      'isRead': isRead,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ContactMessage copyWith({
    int? id,
    String? name,
    String? email,
    String? subject,
    String? message,
    int? userId,
    int? songId,
    int? albumId,
    bool? isRead,
    ContactStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactMessage(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      userId: userId ?? this.userId,
      songId: songId ?? this.songId,
      albumId: albumId ?? this.albumId,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
