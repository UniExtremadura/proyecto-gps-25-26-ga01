import 'package:audira_frontend/core/api/api_client.dart';
import 'package:audira_frontend/core/models/rating.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Create or update a rating
  Future<ApiResponse<Rating>> createRating({
    required int userId,
    required String entityType,
    required int entityId,
    required int ratingValue,
    String? comment,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/ratings',
        body: {
          'userId': userId,
          'entityType': entityType,
          'entityId': entityId,
          'ratingValue': ratingValue,
          if (comment != null) 'comment': comment,
        },
      );

      if (response.success && response.data != null) {
        final rating = Rating.fromJson(response.data);
        return ApiResponse(
          success: true,
          data: rating,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to create rating',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get user's ratings
  Future<ApiResponse<List<Rating>>> getUserRatings(int userId) async {
    try {
      final response = await _apiClient.get('/api/ratings/user/$userId');

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data as List;
        final ratings = data.map((json) => Rating.fromJson(json)).toList();
        return ApiResponse(
          success: true,
          data: ratings,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch user ratings',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get ratings for an entity (song/album/artist)
  Future<ApiResponse<List<Rating>>> getEntityRatings({
    required String entityType,
    required int entityId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/ratings/entity/$entityType/$entityId',
      );

      if (response.success && response.data != null) {
        final List<dynamic> data = response.data as List;
        final ratings = data.map((json) => Rating.fromJson(json)).toList();
        return ApiResponse(
          success: true,
          data: ratings,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch entity ratings',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get average rating and statistics for an entity
  Future<ApiResponse<Map<String, dynamic>>> getEntityRatingStats({
    required String entityType,
    required int entityId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/ratings/entity/$entityType/$entityId/average',
      );

      if (response.success && response.data != null) {
        return ApiResponse(
          success: true,
          data: response.data as Map<String, dynamic>,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch rating stats',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get specific user rating for an entity
  Future<ApiResponse<Rating?>> getUserEntityRating({
    required int userId,
    required String entityType,
    required int entityId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/ratings/user/$userId/entity/$entityType/$entityId',
      );

      if (response.success) {
        if (response.data != null) {
          final rating = Rating.fromJson(response.data);
          return ApiResponse(
            success: true,
            data: rating,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: true,
            data: null,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch user rating',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Delete a rating
  Future<ApiResponse<void>> deleteRating(int ratingId) async {
    try {
      final response = await _apiClient.delete('/api/ratings/$ratingId');

      if (response.success) {
        return ApiResponse(
          success: true,
          data: null,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to delete rating',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
}
