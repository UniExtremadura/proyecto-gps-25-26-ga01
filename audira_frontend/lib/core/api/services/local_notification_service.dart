import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

/// Service to handle local push notifications
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Global navigation key to allow navigation from anywhere
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('LocalNotificationService se ha inicializado correctamente');
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Show a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'audira_channel', // channel ID
      'Audira Notifications', // channel name
      channelDescription: 'Notificaciones de la aplicación Audira',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );

    debugPrint('Notification: $title');
  }

  /// Show notification for purchase success
  Future<void> showPurchaseNotification(String productName) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Compra exitosa',
      body: 'Compra de $productName exitosa',
      priority: NotificationPriority.high,
    );
  }

  /// Show notification for new product from followed artist
  Future<void> showNewProductNotification(
      String artistName, String productName) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Nuevo contenido disponible',
      body: '$artistName ha publicado: $productName',
      priority: NotificationPriority.high,
    );
  }

  /// Show notification for ticket update
  Future<void> showTicketNotification(String title, String message) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      priority: NotificationPriority.high,
    );
  }

  /// Show notification for product review (artist)
  Future<void> showProductReviewNotification(
      String title, String message) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      priority: NotificationPriority.high,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification presionada: ${response.payload}');

    if (response.payload == null || response.payload!.isEmpty) {
      return;
    }

    try {
      final payload = jsonDecode(response.payload!);
      final type = payload['type'] as String?;
      final referenceId = payload['referenceId'] as int?;
      final referenceType = payload['referenceType'] as String?;

      debugPrint(
          'Navigating based on type: $type, referenceId: $referenceId, referenceType: $referenceType');

      navigateBasedOnPayload(type, referenceId, referenceType);
    } catch (e) {
      debugPrint('Error procesando la notificación: $e');
    }
  }

  /// Navigate based on notification payload
  void navigateBasedOnPayload(
      String? type, int? referenceId, String? referenceType) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('Contexto de navegación no disponible');
      return;
    }

    switch (type) {
      // Purchase and order related notifications
      case 'PAYMENT_SUCCESS':
      case 'ORDER_CONFIRMATION':
      case 'PURCHASE_NOTIFICATION':
        Navigator.pushNamed(context, '/profile/purchase-history');
        break;

      // Payment failed - Navigate to purchase history to see details
      case 'PAYMENT_FAILED':
        Navigator.pushNamed(context, '/profile/purchase-history');
        break;

      // New follower - Navigate to followed artists
      case 'NEW_FOLLOWER':
        Navigator.pushNamed(context, '/profile/followed-artists');
        break;

      // New rating - Could navigate to stats or profile
      case 'NEW_RATING':
        Navigator.pushNamed(context, '/stats');
        break;

      // New product notifications
      case 'NEW_PRODUCT':
        if (referenceType != null && referenceId != null) {
          switch (referenceType.toLowerCase()) {
            case 'song':
              Navigator.pushNamed(context, '/song', arguments: referenceId);
              break;
            case 'album':
              Navigator.pushNamed(context, '/album', arguments: referenceId);
              break;
          }
        }
        break;

      // Ticket related notifications
      case 'TICKET_CREATED':
      case 'TICKET_RESPONSE':
      case 'TICKET_RESOLVED':
        Navigator.pushNamed(context, '/profile/tickets');
        break;

      // Product review notifications (for artists)
      case 'PRODUCT_PENDING_REVIEW':
      case 'PRODUCT_APPROVED':
      case 'PRODUCT_REJECTED':
        if (referenceId != null && referenceType != null) {
          switch (referenceType.toLowerCase()) {
            case 'song':
              Navigator.pushNamed(context, '/song', arguments: referenceId);
              break;
            case 'album':
              Navigator.pushNamed(context, '/album', arguments: referenceId);
              break;
            default:
              Navigator.pushNamed(context, '/studio/catalog');
          }
        } else {
          Navigator.pushNamed(context, '/studio/catalog');
        }
        break;

      // Followed artist new content
      case 'FOLLOWED_ARTIST_NEW_CONTENT':
        if (referenceType != null && referenceId != null) {
          switch (referenceType.toLowerCase()) {
            case 'artist':
              Navigator.pushNamed(context, '/artist', arguments: referenceId);
              break;
            case 'song':
              Navigator.pushNamed(context, '/song', arguments: referenceId);
              break;
            case 'album':
              Navigator.pushNamed(context, '/album', arguments: referenceId);
              break;
          }
        }
        break;

      // System notifications - No specific navigation
      case 'SYSTEM_NOTIFICATION':
      default:
        debugPrint(
            'Sin navegación específica para la notificación de tipo: $type');
        break;
    }
  }

  /// Cancel a notification
  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}

enum NotificationPriority {
  min,
  low,
  defaultPriority,
  high,
  max,
}
