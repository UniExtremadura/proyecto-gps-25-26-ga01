import 'package:equatable/equatable.dart';
import 'recommended_song.dart';

/// Response containing personalized recommendations for a user
/// GA01-117: Módulo básico de recomendaciones (placeholder)
class RecommendationsResponse extends Equatable {
  final int userId;
  final DateTime generatedAt;

  // Different categories of recommendations
  final List<RecommendedSong> basedOnListeningHistory;
  final List<RecommendedSong> basedOnPurchases;
  final List<RecommendedSong> fromFollowedArtists;
  final List<RecommendedSong> trending;
  final List<RecommendedSong> newReleases;
  final List<RecommendedSong> similarToFavorites;

  // NEW: More specific recommendation categories
  final List<RecommendedSong> byPurchasedGenres;
  final List<RecommendedSong> byPurchasedArtists;
  final List<RecommendedSong> byLikedSongs;

  // Metadata
  final String algorithm;
  final int totalRecommendations;

  const RecommendationsResponse({
    required this.userId,
    required this.generatedAt,
    required this.basedOnListeningHistory,
    required this.basedOnPurchases,
    required this.fromFollowedArtists,
    required this.trending,
    required this.newReleases,
    required this.similarToFavorites,
    this.byPurchasedGenres = const [],
    this.byPurchasedArtists = const [],
    this.byLikedSongs = const [],
    required this.algorithm,
    required this.totalRecommendations,
  });

  factory RecommendationsResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationsResponse(
      userId: (json['userId'] as num).toInt(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      basedOnListeningHistory:
          _parseRecommendedSongs(json['basedOnListeningHistory']),
      basedOnPurchases: _parseRecommendedSongs(json['basedOnPurchases']),
      fromFollowedArtists: _parseRecommendedSongs(json['fromFollowedArtists']),
      trending: _parseRecommendedSongs(json['trending']),
      newReleases: _parseRecommendedSongs(json['newReleases']),
      similarToFavorites: _parseRecommendedSongs(json['similarToFavorites']),
      byPurchasedGenres: _parseRecommendedSongs(json['byPurchasedGenres']),
      byPurchasedArtists: _parseRecommendedSongs(json['byPurchasedArtists']),
      byLikedSongs: _parseRecommendedSongs(json['byLikedSongs']),
      algorithm: json['algorithm'] as String,
      totalRecommendations: (json['totalRecommendations'] as num).toInt(),
    );
  }

  static List<RecommendedSong> _parseRecommendedSongs(dynamic json) {
    if (json == null) return [];
    if (json is! List) return [];
    return (json)
        .map((item) => RecommendedSong.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'generatedAt': generatedAt.toIso8601String(),
      'basedOnListeningHistory':
          basedOnListeningHistory.map((s) => s.toJson()).toList(),
      'basedOnPurchases': basedOnPurchases.map((s) => s.toJson()).toList(),
      'fromFollowedArtists':
          fromFollowedArtists.map((s) => s.toJson()).toList(),
      'trending': trending.map((s) => s.toJson()).toList(),
      'newReleases': newReleases.map((s) => s.toJson()).toList(),
      'similarToFavorites': similarToFavorites.map((s) => s.toJson()).toList(),
      'byPurchasedGenres': byPurchasedGenres.map((s) => s.toJson()).toList(),
      'byPurchasedArtists': byPurchasedArtists.map((s) => s.toJson()).toList(),
      'byLikedSongs': byLikedSongs.map((s) => s.toJson()).toList(),
      'algorithm': algorithm,
      'totalRecommendations': totalRecommendations,
    };
  }

  /// Get all recommendations as a single flat list
  List<RecommendedSong> getAllRecommendations() {
    return [
      ...basedOnListeningHistory,
      ...basedOnPurchases,
      ...fromFollowedArtists,
      ...trending,
      ...newReleases,
      ...similarToFavorites,
      ...byPurchasedGenres,
      ...byPurchasedArtists,
      ...byLikedSongs,
    ];
  }

  /// Check if there are any recommendations
  bool get hasRecommendations => totalRecommendations > 0;

  @override
  List<Object?> get props => [
        userId,
        generatedAt,
        basedOnListeningHistory,
        basedOnPurchases,
        fromFollowedArtists,
        trending,
        newReleases,
        similarToFavorites,
        byPurchasedGenres,
        byPurchasedArtists,
        byLikedSongs,
        algorithm,
        totalRecommendations,
      ];
}
