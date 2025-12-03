import 'package:equatable/equatable.dart';

/// Tipos de contenido destacado
enum FeaturedContentType {
  song,
  album;

  String toJson() => name;

  static FeaturedContentType fromJson(String value) {
    return FeaturedContentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FeaturedContentType.song,
    );
  }
}

/// Modelo para contenido destacado en la página de inicio
/// GA01-156: Seleccionar/ordenar contenido destacado
/// GA01-157: Programación de destacados
class FeaturedContent extends Equatable {
  final int? id;
  final FeaturedContentType contentType;
  final int contentId;
  final int displayOrder;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? contentTitle;
  final String? contentImageUrl;
  final String? contentArtist;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FeaturedContent({
    this.id,
    required this.contentType,
    required this.contentId,
    required this.displayOrder,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.contentTitle,
    this.contentImageUrl,
    this.contentArtist,
    this.createdAt,
    this.updatedAt,
  });

  /// Verifica si el contenido destacado está dentro del período programado
  bool get isScheduledActive {
    if (!isActive) return false;

    final now = DateTime.now();

    // Si hay fecha de inicio y aún no ha llegado
    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }

    // Si hay fecha de fin y ya pasó
    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }

    return true;
  }

  /// Obtiene el estado de programación como texto
  String get scheduleStatus {
    if (!isActive) return 'Inactivo';

    final now = DateTime.now();

    if (startDate != null && now.isBefore(startDate!)) {
      return 'Programado';
    }

    if (endDate != null && now.isAfter(endDate!)) {
      return 'Finalizado';
    }

    return 'Activo';
  }

  factory FeaturedContent.fromJson(Map<String, dynamic> json) {
    return FeaturedContent(
      id: json['id'] as int?,
      contentType: FeaturedContentType.fromJson(json['contentType'] as String),
      contentId: json['contentId'] as int,
      displayOrder: json['displayOrder'] as int,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      contentTitle: json['contentTitle'] as String?,
      contentImageUrl: json['contentImageUrl'] as String?,
      contentArtist: json['contentArtist'] as String?,
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
      if (id != null) 'id': id,
      'contentType': contentType.toJson(),
      'contentId': contentId,
      'displayOrder': displayOrder,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'isActive': isActive,
      if (contentTitle != null) 'contentTitle': contentTitle,
      if (contentImageUrl != null) 'contentImageUrl': contentImageUrl,
      if (contentArtist != null) 'contentArtist': contentArtist,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  FeaturedContent copyWith({
    int? id,
    FeaturedContentType? contentType,
    int? contentId,
    int? displayOrder,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? contentTitle,
    String? contentImageUrl,
    String? contentArtist,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeaturedContent(
      id: id ?? this.id,
      contentType: contentType ?? this.contentType,
      contentId: contentId ?? this.contentId,
      displayOrder: displayOrder ?? this.displayOrder,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      contentTitle: contentTitle ?? this.contentTitle,
      contentImageUrl: contentImageUrl ?? this.contentImageUrl,
      contentArtist: contentArtist ?? this.contentArtist,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentType,
        contentId,
        displayOrder,
        startDate,
        endDate,
        isActive,
        contentTitle,
        contentImageUrl,
        contentArtist,
        createdAt,
        updatedAt,
      ];
}
