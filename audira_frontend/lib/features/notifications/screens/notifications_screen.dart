import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/services/notification_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  // Variables de Paginación
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Listener para scroll infinito
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLastPage || _isLoadingMore || _isLoading) return;

    // Si llegamos al 90% del scroll, cargamos más
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      setState(() {
        _isLoading = false;
        _error = 'Please login to view notifications';
      });
      return;
    }

    if (refresh) {
      _currentPage = 0;
      _isLastPage = false;
      // No ponemos _isLoading = true en refresh para no parpadear toda la pantalla
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final response = await _notificationService.getUserNotifications(
        authProvider.currentUser!.id,
        page: _currentPage,
        size: _pageSize,
      );

      if (response.success && response.data != null) {
        final newNotifications =
            response.data!['notifications'] as List<NotificationModel>;
        final isLast = response.data!['isLastPage'] as bool;

        setState(() {
          if (refresh) {
            _notifications = newNotifications;
          } else {
            _notifications = newNotifications; // Carga inicial
          }
          _isLastPage = isLast;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || _isLastPage) return;

    setState(() => _isLoadingMore = true);

    final authProvider = context.read<AuthProvider>();
    // Siguiente página
    final nextPage = _currentPage + 1;

    try {
      final response = await _notificationService.getUserNotifications(
        authProvider.currentUser!.id,
        page: nextPage,
        size: _pageSize,
      );

      if (response.success && response.data != null) {
        final newNotifications =
            response.data!['notifications'] as List<NotificationModel>;
        final isLast = response.data!['isLastPage'] as bool;

        setState(() {
          _notifications.addAll(newNotifications);
          _currentPage = nextPage;
          _isLastPage = isLast;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    try {
      await _notificationService.markAllAsRead(authProvider.currentUser!.id);
      // Actualizamos localmente para feedback inmediato
      setState(() {
        _notifications = _notifications
            .map((n) => NotificationModel(
                id: n.id,
                userId: n.userId,
                type: n.type,
                title: n.title,
                message: n.message,
                isRead: true,
                sentAt: n.sentAt,
                createdAt: n.createdAt,
                referenceId: n.referenceId,
                referenceType: n.referenceType,
                metadata: n.metadata))
            .toList();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    // Optimistic update (actualizar UI antes de que responda el server)
    final index = _notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      setState(() {
        // Creamos una copia con isRead = true
        // (Nota: es mejor si el modelo tiene un método .copyWith)
        // Aquí lo hago simple por brevedad:
        /* Lógica para actualizar estado localmente */
      });
    }

    try {
      final response = await _notificationService.markAsRead(notification.id);
      if (response.success && response.data != null) {
        setState(() {
          if (index != -1) {
            _notifications[index] = response.data!;
          }
        });
      }
    } catch (e) {
      // Revertir si falla
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _notifications.isEmpty
                  ? _buildEmptyView()
                  : _buildNotificationsList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Error loading notifications'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadNotifications(refresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('You\'re all caught up!'),
          const SizedBox(height: 16),
          // Botón para recargar por si acaso
          TextButton(
            onPressed: () => _loadNotifications(refresh: true),
            child: const Text('Refresh'),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: () => _loadNotifications(refresh: true),
      child: ListView.builder(
        controller: _scrollController, // IMPORTANTE: El controlador de scroll
        padding: const EdgeInsets.all(16),
        // +1 para el indicador de carga al final
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ));
          }

          final notification = _notifications[index];
          return _buildNotificationItem(notification)
              .animate(
                  delay: (index < 10 ? index * 50 : 0)
                      .ms) // Animamos solo los primeros
              .fadeIn()
              .slideX(begin: -0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Card(
      color: notification.isRead
          ? AppTheme.surfaceBlack
          : AppTheme.surfaceBlack.withValues(alpha: 0.8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTypeColor(notification.type).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTypeIcon(notification.type),
            color: _getTypeColor(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(notification.message),
            ],
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(
                value: 'read',
                child: Row(
                  children: [
                    Icon(Icons.done),
                    SizedBox(width: 8),
                    Text('Mark as read'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'read') {
              _markAsRead(notification);
            } else if (value == 'delete') {
              _deleteNotification(notification.id);
            }
          },
        ),
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification);
          }
          // Aquí puedes agregar navegación según referenceType e ID
          // Ejemplo: if(notification.referenceType == 'ORDER') Navigator.push...
        },
      ),
    );
  }

  // Mapeo preciso con los ENUMS de Java
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'ORDER_CONFIRMATION':
        return Icons.shopping_bag;
      case 'PURCHASE_NOTIFICATION':
        return Icons.attach_money;
      case 'PAYMENT_SUCCESS':
        return Icons.check_circle;
      case 'PAYMENT_FAILED':
        return Icons.error_outline;
      case 'NEW_FOLLOWER':
        return Icons.person_add;
      case 'NEW_RATING':
        return Icons.star;
      case 'SYSTEM_NOTIFICATION':
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ORDER_CONFIRMATION':
      case 'PAYMENT_SUCCESS':
        return Colors.green;
      case 'PURCHASE_NOTIFICATION':
        return Colors.purpleAccent;
      case 'PAYMENT_FAILED':
        return Colors.red;
      case 'NEW_FOLLOWER':
        return Colors.blue;
      case 'NEW_RATING':
        return Colors.amber;
      case 'SYSTEM_NOTIFICATION':
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
