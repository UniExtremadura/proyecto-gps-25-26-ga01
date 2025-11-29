import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart'; // Asegúrate de que este import sea correcto
import '../../../core/api/services/moderation_service.dart';
import '../../../core/models/moderation_history.dart';

class AdminModerationHistoryScreen extends StatefulWidget {
  const AdminModerationHistoryScreen({super.key});

  @override
  State<AdminModerationHistoryScreen> createState() =>
      _AdminModerationHistoryScreenState();
}

class _AdminModerationHistoryScreenState
    extends State<AdminModerationHistoryScreen> {
  final ModerationService _moderationService = ModerationService();

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<ModerationHistory> _history = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _moderationService.getModerationHistory(),
        _moderationService.getModerationStatistics(),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].success) {
            _history = results[0].data as List<ModerationHistory>;
          } else {
            _errorMessage = results[0].error ?? 'Error al cargar historial';
          }

          if (results[1].success) {
            _statistics = results[1].data as Map<String, dynamic>;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar datos: $e';
          _isLoading = false;
        });
      }
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text(
          'Moderation Activity',
          style: TextStyle(
              fontWeight: FontWeight.w800, color: AppTheme.primaryBlue),
        ),
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: AppTheme.primaryBlue),
              onPressed: _loadData,
              tooltip: 'Refresh Data',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // 1. DASHBOARD DE MÉTRICAS
        if (_statistics != null) _buildStatsHeader(),

        // 2. TÍTULO DE LISTA
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              Icon(Icons.history_toggle_off, color: subText, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recent Logs',
                style: TextStyle(
                    color: subText,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: darkCardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[800]!)),
                child: Text(
                  '${_history.length} items',
                  style: TextStyle(color: lightText, fontSize: 12),
                ),
              )
            ],
          ),
        ),

        // 3. LISTA CRONOLÓGICA
        Expanded(
          child: _history.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineCard(_history[index], index);
                  },
                ),
        ),
      ],
    );
  }

  // --- WIDGETS DE ESTADÍSTICAS ---

  Widget _buildStatsHeader() {
    // Calcular porcentajes simples para la barra visual
    int approved = _statistics!['totalApproved'] ?? 0;
    int rejected = _statistics!['totalRejected'] ?? 0;
    int pending = _statistics!['totalPending'] ?? 0;
    int total = approved + rejected + pending;
    if (total == 0) total = 1;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: darkCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[850]!),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Approved', approved, Colors.greenAccent),
              Container(width: 1, height: 40, color: Colors.grey[800]),
              _buildStatItem('Rejected', rejected, Colors.redAccent),
              Container(width: 1, height: 40, color: Colors.grey[800]),
              _buildStatItem('Pending', pending, Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 24),
          // Barra de progreso visual
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                      flex: approved,
                      child: Container(color: Colors.greenAccent)),
                  Expanded(
                      flex: rejected,
                      child: Container(color: Colors.redAccent)),
                  Expanded(
                      flex: pending,
                      child: Container(color: Colors.orangeAccent)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${((approved / total) * 100).toInt()}% approval rate',
                  style: TextStyle(color: subText, fontSize: 11)),
              Text('Total Actions: $total',
                  style: TextStyle(color: subText, fontSize: 11)),
            ],
          )
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(),
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: subText)),
      ],
    );
  }

  // --- WIDGETS DE LISTA (TIMELINE) ---

  Widget _buildTimelineCard(ModerationHistory entry, int index) {
    final statusColor = _getStatusColor(entry.newStatus);
    final icon = _getStatusIcon(entry.newStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      // IntrinsicHeight permite que la línea de tiempo (izquierda) crezca igual que la tarjeta (derecha)
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- COLUMNA DE TIEMPO (Izquierda) ---
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  Text(
                    DateFormat('HH:mm').format(entry.moderatedAt),
                    style: const TextStyle(
                      color: Colors.white, // Forzamos blanco
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM').format(entry.moderatedAt),
                    style: const TextStyle(
                      color: Colors.grey, // Forzamos gris
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Línea vertical
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),

            // --- TARJETA DE CONTENIDO (Derecha) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4.0), // Pequeño espacio
                child: Material(
                  color:
                      const Color(0xFF212121), // Color de fondo de la tarjeta
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior:
                      Clip.antiAlias, // Asegura que el InkWell no se salga
                  child: InkWell(
                    onTap: () => _showHistoryDetails(entry),
                    // Borde lateral de color indicador
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: statusColor, width: 4),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Título y Tipo
                          Row(
                            children: [
                              Icon(
                                entry.productType == 'SONG'
                                    ? Icons.music_note
                                    : Icons.album,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.productTitle,
                                  style: const TextStyle(
                                    color: Colors.white, // Texto Blanco
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Icono de estado pequeño
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, size: 14, color: statusColor),
                              )
                            ],
                          ),

                          const SizedBox(height: 8),

                          // 2. Transición de Estado (Ej: Pending -> Approved)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  entry.previousStatusDisplay,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.arrow_forward,
                                      size: 12, color: Colors.grey),
                                ),
                                Text(
                                  entry.newStatusDisplay,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 3. Footer: Moderador y Motivo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.grey[800],
                                    child: const Icon(Icons.person,
                                        size: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    entry.moderatorName ??
                                        'Admin #${entry.moderatedBy}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              if (entry.rejectionReason != null)
                                Icon(Icons.comment,
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.7),
                                    size: 16)
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.1, end: 0);
  }

  // --- DIALOGO DE DETALLE (DARK MODE) ---

  void _showHistoryDetails(ModerationHistory entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey[800]!)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color:
                      _getStatusColor(entry.newStatus).withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              child: Icon(_getStatusIcon(entry.newStatus),
                  color: _getStatusColor(entry.newStatus), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Action Details',
                    style: TextStyle(color: lightText, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Product', entry.productTitle, Icons.label),
            _buildDetailItem('Type',
                entry.productType == 'SONG' ? 'Song' : 'Album', Icons.category),
            _buildDetailItem(
                'Artist', entry.artistName ?? 'Unknown', Icons.person),
            const Divider(color: Colors.grey),
            _buildDetailItem(
                'Moderator',
                entry.moderatorName ?? 'ID: ${entry.moderatedBy}',
                Icons.admin_panel_settings),
            _buildDetailItem('Date', _formatDateLong(entry.moderatedAt),
                Icons.calendar_today),
            if (entry.rejectionReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rejection Reason',
                        style: TextStyle(
                            color: Colors.red[200],
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(entry.rejectionReason!,
                        style: TextStyle(color: lightText, fontSize: 14)),
                  ],
                ),
              )
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: subText),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: subText, fontSize: 11)),
              Text(value,
                  style: TextStyle(
                      color: lightText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  // --- HELPERS Y ERROR VIEW ---

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.red[900]),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[850]),
          const SizedBox(height: 16),
          Text('No moderation history yet',
              style: TextStyle(color: subText, fontSize: 16)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orangeAccent;
      case 'APPROVED':
        return Colors.greenAccent;
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.hourglass_top;
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDateLong(DateTime date) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(date);
  }
}
