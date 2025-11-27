import 'dart:async';
import 'package:audira_frontend/core/api/api_client.dart';
import 'package:audira_frontend/core/api/services/local_notification_service.dart';
import 'package:flutter/foundation.dart';
import '../../models/notification_model.dart'; // Asegúrate de importar el modelo

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiClient _apiClient = ApiClient();
  final LocalNotificationService _localNotifications = LocalNotificationService();

  Timer? _pollingTimer;
  int? _currentUserId;
  Set<int> _seenNotificationIds = {};
  bool _isPolling = false;

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

  /// Start polling for new notifications
  Future<void> startPolling(int userId, {Duration interval = const Duration(seconds: 30)}) async {
    if (_isPolling && _currentUserId == userId) {
      debugPrint('Already polling for user $userId');
      return;
    }

    stopPolling();

    _currentUserId = userId;
    _isPolling = true;

    // Initialize local notifications
    await _localNotifications.initialize();
    await _localNotifications.requestPermissions();

    // Load initial notifications to populate seen IDs
    final initialResponse = await getUserNotifications(userId, page: 0, size: 20);
    if (initialResponse.success && initialResponse.data != null) {
      final notifications = initialResponse.data!['notifications'] as List<NotificationModel>;
      _seenNotificationIds = notifications.map((n) => n.id).toSet();
    }

    // Start periodic polling
    _pollingTimer = Timer.periodic(interval, (timer) async {
      await _checkForNewNotifications(userId);
    });

    debugPrint('Started polling notifications for user $userId every ${interval.inSeconds}s');
  }

  /// Stop polling for notifications
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    _currentUserId = null;
    debugPrint('Stopped polling notifications');
  }

  /// Check for new notifications and show local push notifications
  Future<void> _checkForNewNotifications(int userId) async {
    try {
      final response = await getUserNotifications(userId, page: 0, size: 20);

      if (response.success && response.data != null) {
        final notifications = response.data!['notifications'] as List<NotificationModel>;

        for (var notification in notifications) {
          // Only show notification if it's new and unread
          if (!_seenNotificationIds.contains(notification.id) && !notification.isRead) {
            _seenNotificationIds.add(notification.id);
            await _showLocalNotification(notification);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for new notifications: $e');
    }
  }

  /// Show local push notification based on notification type
  Future<void> _showLocalNotification(NotificationModel notification) async {
    try {
      switch (notification.type) {
        case 'PAYMENT_SUCCESS':
        case 'ORDER_CONFIRMATION':
          await _localNotifications.showNotification(
            id: notification.id,
            title: notification.title,
            body: notification.message,
            priority: NotificationPriority.high,
          );
          break;

        case 'PURCHASE_NOTIFICATION':
          await _localNotifications.showNotification(
            id: notification.id,
            title: notification.title,
            body: notification.message,
            priority: NotificationPriority.high,
          );
          break;

        case 'NEW_PRODUCT':
          await _localNotifications.showNotification(
            id: notification.id,
            title: notification.title,
            body: notification.message,
            priority: NotificationPriority.high,
          );
          break;

        case 'TICKET_CREATED':
        case 'TICKET_RESPONSE':
        case 'TICKET_RESOLVED':
          await _localNotifications.showTicketNotification(
            notification.title,
            notification.message,
          );
          break;

        case 'PRODUCT_PENDING_REVIEW':
        case 'PRODUCT_APPROVED':
        case 'PRODUCT_REJECTED':
          await _localNotifications.showProductReviewNotification(
            notification.title,
            notification.message,
          );
          break;

        default:
          await _localNotifications.showNotification(
            id: notification.id,
            title: notification.title,
            body: notification.message,
          );
      }

      debugPrint('Local notification shown: ${notification.title}');
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopPolling();
  }
}
