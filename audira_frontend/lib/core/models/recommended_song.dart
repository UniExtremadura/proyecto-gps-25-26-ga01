import 'package:equatable/equatable.dart';

/// Represents a recommended song with metadata about why it was recommended
/// GA01-117: Módulo básico de recomendaciones (placeholder)
class RecommendedSong extends Equatable {
  final int id;
  final String title;
  final int artistId;
  final String artistName;
  final String? imageUrl;
  final double? price;
  final int plays;
  final String? reason; // Why this song was recommended (can be null)
  final double relevanceScore; // Score from 0.0 to 1.0

  const RecommendedSong({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    this.imageUrl,
    this.price,
    required this.plays,
    this.reason,
    required this.relevanceScore,
  });

  factory RecommendedSong.fromJson(Map<String, dynamic> json) {
    return RecommendedSong(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? 'Sin título',
      artistId: (json['artistId'] as num).toInt(),
      artistName: json['artistName'] as String? ?? 'Artista desconocido',
      imageUrl: json['imageUrl'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      plays: (json['plays'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String?,
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artistId': artistId,
      'artistName': artistName,
      'imageUrl': imageUrl,
      'price': price,
      'plays': plays,
      'reason': reason,
      'relevanceScore': relevanceScore,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artistId,
        artistName,
        imageUrl,
        price,
        plays,
        reason,
        relevanceScore,
      ];
}
