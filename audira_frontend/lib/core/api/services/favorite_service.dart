import '../api_client.dart';
import '../../../config/constants.dart';

class FavoriteService {
  final ApiClient _apiClient = ApiClient();

  /// Get user's complete favorites organized by type
  Future<ApiResponse<UserFavorites>> getUserFavorites(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.favoritesUrl}/user/$userId',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(
          success: true, data: UserFavorites.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get all favorites (flat list)
  Future<ApiResponse<List<FavoriteData>>> getAllFavorites(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.favoritesUrl}/user/$userId/items',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      final items = (response.data as List)
          .map((json) => FavoriteData.fromJson(json))
          .toList();
      return ApiResponse(success: true, data: items);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get favorites of a specific type
  Future<ApiResponse<List<FavoriteData>>> getFavoritesByType(
    int userId,
    String itemType,
  ) async {
    final response = await _apiClient.get(
      '${AppConstants.favoritesUrl}/user/$userId/items/$itemType',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      final items = (response.data as List)
          .map((json) => FavoriteData.fromJson(json))
          .toList();
      return ApiResponse(success: true, data: items);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Check if user has favorited a specific item
  Future<ApiResponse<bool>> checkIfFavorite(
    int userId,
    String itemType,
    int itemId,
  ) async {
    final response = await _apiClient.get(
      '${AppConstants.favoritesUrl}/user/$userId/check/$itemType/$itemId',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data as bool);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Add an item to favorites
  Future<ApiResponse<FavoriteData>> addFavorite(
    int userId,
    String itemType,
    int itemId,
  ) async {
    final response = await _apiClient.post(
      '${AppConstants.favoritesUrl}/user/$userId',
      body: {
        'itemType': itemType,
        'itemId': itemId,
      },
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(
          success: true, data: FavoriteData.fromJson(response.data));
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Remove an item from favorites
  Future<ApiResponse<void>> removeFavorite(
    int userId,
    String itemType,
    int itemId,
  ) async {
    return await _apiClient.delete(
      '${AppConstants.favoritesUrl}/user/$userId/$itemType/$itemId',
      requiresAuth: false,
    );
  }

  /// Toggle favorite status (add if not exists, remove if exists)
  Future<ApiResponse<bool>> toggleFavorite(
    int userId,
    String itemType,
    int itemId,
  ) async {
    final response = await _apiClient.post(
      '${AppConstants.favoritesUrl}/user/$userId/toggle',
      body: {
        'itemType': itemType,
        'itemId': itemId,
      },
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(
          success: true, data: response.data['isFavorite'] as bool);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get favorite count for a user
  Future<ApiResponse<int>> getFavoriteCount(int userId) async {
    final response = await _apiClient.get(
      '${AppConstants.favoritesUrl}/user/$userId/count',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data as int);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Get favorite count by type
  Future<ApiResponse<int>> getFavoriteCountByType(
    int userId,
    String itemType,
  ) async {
    final response = await _apiClient.get(
      '${AppConstants.favoritesUrl}/user/$userId/count/$itemType',
      requiresAuth: false,
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data as int);
    }
    return ApiResponse(success: false, error: response.error);
  }

  /// Clear all favorites for a user (for testing)
  Future<ApiResponse<void>> clearUserFavorites(int userId) async {
    return await _apiClient.delete(
      '${AppConstants.favoritesUrl}/user/$userId',
      requiresAuth: false,
    );
  }
}

/// Model for favorite item data from the API
class FavoriteData {
  final int id;
  final int userId;
  final String itemType;
  final int itemId;
  final DateTime createdAt;

  FavoriteData({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.itemId,
    required this.createdAt,
  });

  factory FavoriteData.fromJson(Map<String, dynamic> json) {
    return FavoriteData(
      id: json['id'] as int,
      userId: json['userId'] as int,
      itemType: json['itemType'] as String,
      itemId: json['itemId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'itemType': itemType,
      'itemId': itemId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Model for user favorites from the API
class UserFavorites {
  final int userId;
  final List<FavoriteData> songs;
  final List<FavoriteData> albums;
  final List<FavoriteData> merchandise;
  final int totalFavorites;

  UserFavorites({
    required this.userId,
    required this.songs,
    required this.albums,
    required this.merchandise,
    required this.totalFavorites,
  });

  factory UserFavorites.fromJson(Map<String, dynamic> json) {
    return UserFavorites(
      userId: json['userId'] as int,
      songs: (json['songs'] as List<dynamic>? ?? [])
          .map((item) => FavoriteData.fromJson(item as Map<String, dynamic>))
          .toList(),
      albums: (json['albums'] as List<dynamic>? ?? [])
          .map((item) => FavoriteData.fromJson(item as Map<String, dynamic>))
          .toList(),
      merchandise: (json['merchandise'] as List<dynamic>? ?? [])
          .map((item) => FavoriteData.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalFavorites: json['totalFavorites'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'songs': songs.map((s) => s.toJson()).toList(),
      'albums': albums.map((a) => a.toJson()).toList(),
      'merchandise': merchandise.map((m) => m.toJson()).toList(),
      'totalFavorites': totalFavorites,
    };
  }
}
