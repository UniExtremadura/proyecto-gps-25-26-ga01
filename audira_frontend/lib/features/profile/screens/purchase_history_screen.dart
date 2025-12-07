import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/order_service.dart';
import '../../../core/models/order.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final OrderService _orderService = OrderService();

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPurchaseHistory();
  }

  Future<void> _loadPurchaseHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      setState(() {
        _error = 'Usuario desconocido';
        _isLoading = false;
      });
      return;
    }

    final response = await _orderService.getOrdersByUserId(userId);

    if (response.success && response.data != null) {
      setState(() {
        _orders = response.data!;
        _orders.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.error ?? 'Error cargando historial';
        _isLoading = false;
      });
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('Mis compras',
            style: TextStyle(
                color: AppTheme.primaryBlue, fontWeight: FontWeight.w800)),
        backgroundColor: darkBg,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _error != null
              ? _buildErrorView()
              : _orders.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPurchaseHistory,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _orders.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildOrderCard(_orders[index], index);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration:
                BoxDecoration(color: darkCardBg, shape: BoxShape.circle),
            child: Icon(Icons.shopping_bag_outlined,
                size: 64, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          Text('No has realizado compras aún',
              style: TextStyle(color: subText, fontSize: 18)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red[900]),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadPurchaseHistory, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, int index) {
    final statusColor = _getStatusColor(order.status);
    final statusText = _translateStatus(order.status);

    return InkWell(
      onTap: () => _showOrderDetails(order),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: darkCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[850]!),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${order.orderNumber}',
                        style: TextStyle(
                            color: lightText,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order.createdAt),
                        style: TextStyle(color: subText, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Colors.grey),

            // Content Summary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.shopping_basket, size: 18, color: subText),
                  const SizedBox(width: 8),
                  Text('${order.items.length} items',
                      style: TextStyle(color: subText, fontSize: 14)),
                  const Spacer(),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: lightText,
                        fontWeight: FontWeight.w900,
                        fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  // --- DETAILS SHEET (DARK MODE) ---

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: darkCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('Detalles del pedido',
                  style: TextStyle(
                      color: lightText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text('#${order.orderNumber}',
                  style: TextStyle(color: subText, fontSize: 14)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildInfoRow('Status', _translateStatus(order.status),
                        color: _getStatusColor(order.status)),
                    _buildInfoRow('Date', _formatDate(order.createdAt)),
                    if (order.shippingAddress != null)
                      _buildInfoRow('Address', order.shippingAddress!),
                    const SizedBox(height: 24),
                    Text('Items',
                        style: TextStyle(
                            color: lightText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...order.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Icon(
                                    item.itemType.toUpperCase() == 'SONG'
                                        ? Icons.music_note
                                        : Icons.album,
                                    color: AppTheme.primaryBlue,
                                    size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_translateItemType(item.itemType),
                                        style: TextStyle(
                                            color: lightText,
                                            fontWeight: FontWeight.bold)),
                                    Text('ID: ${item.itemId}',
                                        style: TextStyle(
                                            color: subText, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      '\$${item.totalPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: lightText,
                                          fontWeight: FontWeight.bold)),
                                  Text('Qty: ${item.quantity}',
                                      style: TextStyle(
                                          color: subText, fontSize: 12)),
                                ],
                              )
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total a pagar',
                              style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text('\$${order.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: subText)),
          Text(value,
              style: TextStyle(
                  color: color ?? lightText, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- HELPERS ---

  String _formatDate(DateTime? date) =>
      date == null ? 'N/A' : DateFormat('dd/MM/yyyy HH:mm').format(date);

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return Colors.greenAccent;
      case 'CANCELLED':
        return Colors.redAccent;
      case 'PENDING':
        return Colors.orangeAccent;
      case 'PROCESSING':
        return Colors.blueAccent;
      case 'SHIPPED':
        return Colors.cyanAccent;
      default:
        return Colors.grey;
    }
  }

  String _translateStatus(String status) {
    // Mantengo la lógica de traducción original pero simplificada
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'PROCESSING':
        return 'Processing';
      case 'SHIPPED':
        return 'Shipped';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _translateItemType(String itemType) {
    switch (itemType.toUpperCase()) {
      case 'SONG':
        return 'Song';
      case 'ALBUM':
        return 'Album';
      default:
        return itemType;
    }
  }
}
