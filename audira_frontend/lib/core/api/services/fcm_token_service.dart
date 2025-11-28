import 'package:audira_frontend/core/api/api_client.dart';
import 'package:flutter/foundation.dart';

/// Service to register and manage FCM tokens with the backend
class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();
  factory FcmTokenService() => _instance;
  FcmTokenService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Register FCM token for a user
  Future<ApiResponse<void>> registerToken(int userId, String fcmToken) async {
    try {
      debugPrint('Registering FCM token for user $userId');

      final response = await _apiClient.post(
        '/api/notifications/fcm/register',
        body: {
          'userId': userId,
          'token': fcmToken,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID',
        },
      );

      if (response.success) {
        debugPrint('FCM token registered successfully');
        return ApiResponse(
          success: true,
          data: null,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to register FCM token',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Delete FCM token for a user (when logging out)
  Future<ApiResponse<void>> deleteToken(int userId, String fcmToken) async {
    try {
      debugPrint('Deleting FCM token for user $userId');

      final response = await _apiClient.delete(
        '/api/notifications/fcm/unregister',
        body: {
          'userId': userId,
          'token': fcmToken,
        },
      );

      if (response.success) {
        debugPrint('FCM token deleted successfully');
        return ApiResponse(
          success: true,
          data: null,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to delete FCM token',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Update FCM token when it refreshes
  Future<ApiResponse<void>> updateToken(int userId, String oldToken, String newToken) async {
    try {
      debugPrint('Updating FCM token for user $userId');

      // Delete old token
      await deleteToken(userId, oldToken);

      // Register new token
      return await registerToken(userId, newToken);
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      return ApiResponse(success: false, error: e.toString());
    }
  }
}
