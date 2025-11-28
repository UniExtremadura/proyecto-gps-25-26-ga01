import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:audira_frontend/core/api/services/local_notification_service.dart';
import 'package:audira_frontend/core/api/services/fcm_token_service.dart';

/// Top-level function to handle background messages
/// Must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
}

/// Service to handle Firebase Cloud Messaging
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotifications = LocalNotificationService();
  final FcmTokenService _tokenService = FcmTokenService();

  String? _fcmToken;
  int? _currentUserId;
  bool _initialized = false;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging
  Future<void> initialize({int? userId}) async {
    if (_initialized) return;

    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        // Initialize local notifications
        await _localNotifications.initialize();
        await _localNotifications.requestPermissions();

        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('FCM Token: $_fcmToken');

        // Register token with backend if userId is provided
        if (userId != null && _fcmToken != null) {
          _currentUserId = userId;
          await _tokenService.registerToken(userId, _fcmToken!);
        }

        // Listen to token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          final oldToken = _fcmToken;
          _fcmToken = newToken;
          debugPrint('FCM Token refreshed: $newToken');

          // Update token on backend
          if (_currentUserId != null && oldToken != null) {
            await _tokenService.updateToken(_currentUserId!, oldToken, newToken);
          }
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        // Handle notification taps when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Check if app was opened from a terminated state via notification
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }

        _initialized = true;
        debugPrint('FirebaseMessagingService initialized successfully');
      } else {
        debugPrint('FCM Permission denied');
      }
    } catch (e) {
      debugPrint('Error initializing FirebaseMessagingService: $e');
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
    debugPrint('Message notification: ${message.notification?.title}');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  /// Handle notification tap when app is in background
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.messageId}');
    debugPrint('Message data: ${message.data}');

    // Navigate based on message data
    _navigateBasedOnData(message.data);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      // Create payload from message data
      final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;

      await _localNotifications.showNotification(
        id: message.messageId.hashCode,
        title: notification.title ?? 'Audira',
        body: notification.body ?? '',
        payload: payload,
        priority: NotificationPriority.high,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Navigate based on notification data
  void _navigateBasedOnData(Map<String, dynamic> data) {
    final context = LocalNotificationService.navigatorKey.currentContext;
    if (context == null) {
      debugPrint('Navigation context is null');
      return;
    }

    try {
      final type = data['type'] as String?;
      final referenceId = data['referenceId'] != null
          ? int.tryParse(data['referenceId'].toString())
          : null;
      final referenceType = data['referenceType'] as String?;

      debugPrint('Navigating: type=$type, referenceId=$referenceId, referenceType=$referenceType');

      if (type == null) return;

      // Use the same navigation logic as local notifications
      _localNotifications.navigateBasedOnPayload(type, referenceId, referenceType);
    } catch (e) {
      debugPrint('Error parsing notification data: $e');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      // Delete token from backend
      if (_currentUserId != null && _fcmToken != null) {
        await _tokenService.deleteToken(_currentUserId!, _fcmToken!);
      }

      // Delete token from Firebase
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      _currentUserId = null;
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}
