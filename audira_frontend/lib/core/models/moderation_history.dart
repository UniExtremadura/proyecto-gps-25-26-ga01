import 'package:equatable/equatable.dart';

/// GA01-163: Modelo para historial de moderaciones
class ModerationHistory extends Equatable {
  final int id;
  final int productId;
  final String productType; // SONG o ALBUM
  final String productTitle;
  final int artistId;
  final String? artistName;
  final String? previousStatus;
  final String newStatus;
  final int moderatedBy;
  final String? moderatorName;
  final String? rejectionReason;
  final DateTime moderatedAt;
  final String? notes;

  const ModerationHistory({
    required this.id,
    required this.productId,
    required this.productType,
    required this.productTitle,
    required this.artistId,
    this.artistName,
    this.previousStatus,
    required this.newStatus,
    required this.moderatedBy,
    this.moderatorName,
    this.rejectionReason,
    required this.moderatedAt,
    this.notes,
  });

  factory ModerationHistory.fromJson(Map<String, dynamic> json) {
    return ModerationHistory(
      id: json['id'] as int,
      productId: json['productId'] as int,
      productType: json['productType'] as String,
      productTitle: json['productTitle'] as String,
      artistId: json['artistId'] as int,
      artistName: json['artistName'] as String?,
      previousStatus: json['previousStatus'] as String?,
      newStatus: json['newStatus'] as String,
      moderatedBy: json['moderatedBy'] as int,
      moderatorName: json['moderatorName'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      moderatedAt: DateTime.parse(json['moderatedAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  String get newStatusDisplay {
    switch (newStatus) {
      case 'PENDING':
        return 'En revisión';
      case 'APPROVED':
        return 'Aprobado';
      case 'REJECTED':
        return 'Rechazado';
      default:
        return newStatus;
    }
  }

  String get previousStatusDisplay {
    if (previousStatus == null) return '-';
    switch (previousStatus) {
      case 'PENDING':
        return 'En revisión';
      case 'APPROVED':
        return 'Aprobado';
      case 'REJECTED':
        return 'Rechazado';
      default:
        return previousStatus!;
    }
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productType,
        productTitle,
        artistId,
        artistName,
        previousStatus,
        newStatus,
        moderatedBy,
        moderatorName,
        rejectionReason,
        moderatedAt,
        notes,
      ];
}
