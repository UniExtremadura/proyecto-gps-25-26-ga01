class ContactResponse {
  final int id;
  final int contactMessageId;
  final int adminId;
  final String adminName;
  final String response;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactResponse({
    required this.id,
    required this.contactMessageId,
    required this.adminId,
    required this.adminName,
    required this.response,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactResponse.fromJson(Map<String, dynamic> json) {
    return ContactResponse(
      id: json['id'] as int,
      contactMessageId: json['contactMessageId'] as int,
      adminId: json['adminId'] as int,
      adminName: json['adminName'] as String,
      response: json['response'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactMessageId': contactMessageId,
      'adminId': adminId,
      'adminName': adminName,
      'response': response,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
