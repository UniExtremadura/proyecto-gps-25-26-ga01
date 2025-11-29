// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  // --- Colores del Tema Oscuro (Consistencia Global) ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  // --- Datos Mock ---
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 1001,
      'userId': 123,
      'userName': 'John Doe',
      'userAvatar': 'J',
      'items': ['Canción: Midnight Dreams', 'Álbum: Summer Vibes'],
      'total': 25.98,
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'completed',
    },
    {
      'id': 1002,
      'userId': 456,
      'userName': 'Jane Smith',
      'userAvatar': 'J',
      'items': ['Canción: Electric Love'],
      'total': 9.99,
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'pending',
    },
    {
      'id': 1003,
      'userId': 789,
      'userName': 'Bob Johnson',
      'userAvatar': 'B',
      'items': ['Álbum: Jazz Collection', 'Canción: Blue Notes'],
      'total': 34.97,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'completed',
    },
    {
      'id': 1004,
      'userId': 999,
      'userName': 'Alice Cooper',
      'userAvatar': 'A',
      'items': ['Álbum: Heavy Metal'],
      'total': 15.00,
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'cancelled',
    },
  ];

  String _selectedFilter = 'ALL';

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'ALL') return _orders;
    return _orders
        .where((o) => o['status'] == _selectedFilter.toLowerCase())
        .toList();
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    // Calculamos totales dinámicamente
    final double totalRevenue = _orders.fold<double>(
        0,
        (sum, order) =>
            order['status'] != 'cancelled' ? sum + order['total'] : sum);

    return Scaffold(
      backgroundColor: darkBg, // FONDO NEGRO
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Administrar Pedidos',
          style: TextStyle(
              color: AppTheme.primaryBlue, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // 1. SECCIÓN DE ESTADÍSTICAS
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildDashboardStat(
                    'Pedidos Totales',
                    _orders.length.toString(),
                    Icons.shopping_bag_outlined,
                    AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDashboardStat(
                    'Ingresos',
                    '\$${totalRevenue.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.greenAccent[400]!,
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: -0.2, end: 0, duration: 400.ms),

          // 2. FILTROS (CHIPS)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'Todos los Pedidos'),
                const SizedBox(width: 10),
                _buildFilterChip('PENDING', 'Pendientes'),
                const SizedBox(width: 10),
                _buildFilterChip('COMPLETED', 'Completados'),
                const SizedBox(width: 10),
                _buildFilterChip('CANCELLED', 'Cancelados'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. LISTA DE ÓRDENES
          Expanded(
            child: _filteredOrders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_filteredOrders[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildDashboardStat(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: lightText,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: subText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey[800]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : subText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    final Color statusColor = _getStatusColor(order['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Theme(
        // Quitamos las líneas divisoras feas del ExpansionTile por defecto
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          // --- CABECERA DE LA TARJETA ---
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '#${order['id']}',
                    style: TextStyle(
                      fontFamily: 'Courier', // Estilo "Ticket"
                      color: subText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(order['date']),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              _buildStatusBadge(order['status'], statusColor),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  child: Text(
                    order['userName'][0],
                    style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['userName'],
                      style: TextStyle(
                          color: lightText,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    Text(
                      '\$${order['total'].toStringAsFixed(2)}',
                      style: TextStyle(
                          color: Colors.greenAccent[400],
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // --- CONTENIDO EXPANDIDO ---
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ARTÍCULOS DEL PEDIDO',
                    style: TextStyle(
                        color: subText,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  ...order['items'].map<Widget>((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.music_note, size: 14, color: subText),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(item,
                                    style: TextStyle(
                                        color: lightText.withValues(alpha: 0.9),
                                        fontSize: 13))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (order['status'] == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      order['status'] = 'completed';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Pedido marcado como completado'),
                          backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Marcar como Completado'),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildStatusBadge(String status, Color color) {
    String translatedStatus;
    switch (status) {
      case 'pending':
        translatedStatus = 'PENDIENTE';
        break;
      case 'completed':
        translatedStatus = 'COMPLETADO';
        break;
      case 'cancelled':
        translatedStatus = 'CANCELADO';
        break;
      default:
        translatedStatus = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        translatedStatus,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            'No se encontraron pedidos',
            style: TextStyle(color: subText, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- LOGIC HELPERS ---

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent;
      case 'completed':
        return Colors.greenAccent[400]!;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 24) {
      return 'hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'hace ${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
