import 'package:audira_frontend/core/api/api_client.dart';
import '../../models/notification_model.dart'; // Asegúrate de importar el modelo

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get user's notifications (Paginado)
  /// Devuelve una lista de notificaciones y un booleano indicando si es la última página
  Future<ApiResponse<Map<String, dynamic>>> getUserNotifications(int userId,
      {int page = 0, int size = 20}) async {
    try {
      // Agregamos query params para la paginación de Spring Boot
      final response = await _apiClient
          .get('/api/notifications/user/$userId?page=$page&size=$size');

      if (response.success && response.data != null) {
        // Spring devuelve un objeto Page: { "content": [], "last": false, ... }
        final dataMap = response.data as Map<String, dynamic>;
        final List<dynamic> content = dataMap['content'] ?? [];
        final bool last = dataMap['last'] ?? true;

        final notifications =
            content.map((json) => NotificationModel.fromJson(json)).toList();

        return ApiResponse(
          success: true,
          data: {
            'notifications': notifications,
            'isLastPage': last,
          },
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch notifications',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Get unread notifications count
  Future<ApiResponse<int>> getUnreadCount(int userId) async {
    try {
      final response =
          await _apiClient.get('/api/notifications/user/$userId/unread/count');

      if (response.success && response.data != null) {
        // El backend devuelve map: {"count": 5}
        final count =
            (response.data is Map) ? response.data['count'] : response.data;

        return ApiResponse(
          success: true,
          data: count as int,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to fetch unread count',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Mark notification as read
  Future<ApiResponse<NotificationModel>> markAsRead(int notificationId) async {
    try {
      final response =
          await _apiClient.patch('/api/notifications/$notificationId/read');

      if (response.success && response.data != null) {
        return ApiResponse(
          success: true,
          data: NotificationModel.fromJson(response.data),
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to mark as read',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Mark all notifications as read
  Future<ApiResponse<void>> markAllAsRead(int userId) async {
    try {
      final response =
          await _apiClient.patch('/api/notifications/user/$userId/read-all');

      if (response.success) {
        return ApiResponse(
          success: true,
          data: null,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to mark all as read',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  /// Delete notification
  Future<ApiResponse<void>> deleteNotification(int notificationId) async {
    try {
      final response =
          await _apiClient.delete('/api/notifications/$notificationId');

      if (response.success) {
        return ApiResponse(
          success: true,
          data: null,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        error: response.error ?? 'Failed to delete notification',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  // Nota: El backend no tenía endpoint para borrar TODAS.
  // Si lo añadiste, descomenta esto. Si no, quítalo.
  /*
  Future<ApiResponse<void>> deleteAllNotifications(int userId) async { ... }
  */
}
