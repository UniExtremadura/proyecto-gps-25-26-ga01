import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/contact_message.dart';
import '../../../core/models/contact_response.dart';
import '../../../core/models/contact_status.dart';
import '../../../core/api/services/contact_service.dart';
import '../../../core/providers/auth_provider.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final ContactService _contactService = ContactService();

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<ContactMessage> _tickets = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _contactService.getMessagesByUserId(
        authProvider.currentUser!.id,
      );

      if (response.success && response.data != null) {
        setState(() {
          _tickets = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Error cargando tickets';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  List<ContactMessage> get _filteredTickets {
    if (_selectedFilter == 'ALL') return _tickets;
    // Simple filter matching enum name
    try {
      final status = ContactStatus.values.firstWhere((e) =>
          e.toString().split('.').last.toUpperCase() == _selectedFilter ||
          e.value == _selectedFilter);
      return _tickets.where((t) => t.status == status).toList();
    } catch (e) {
      return _tickets;
    }
  }

  Color _getStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.pending:
        return Colors.orangeAccent;
      case ContactStatus.inProgress:
        return Colors.blueAccent;
      case ContactStatus.resolved:
        return Colors.greenAccent;
      case ContactStatus.closed:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ContactStatus status) {
    switch (status) {
      case ContactStatus.pending:
        return Icons.hourglass_empty;
      case ContactStatus.inProgress:
        return Icons.sync;
      case ContactStatus.resolved:
        return Icons.check_circle_outline;
      case ContactStatus.closed:
        return Icons.lock_outline;
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('Mis tickets',
            style: TextStyle(
                color: AppTheme.primaryBlue, fontWeight: FontWeight.w800)),
        backgroundColor: darkBg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
            onPressed: _loadTickets,
            tooltip: 'Recargar tickets',
          ),
          // Filter Popup
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: AppTheme.primaryBlue),
            color: darkCardBg,
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'ALL',
                  child: Text('Todos los tickets',
                      style: TextStyle(color: Colors.white))),
              const PopupMenuItem(
                  value: 'PENDING',
                  child: Text('Pendientes',
                      style: TextStyle(color: Colors.white))),
              const PopupMenuItem(
                  value: 'IN_PROGRESS',
                  child: Text('In Progress',
                      style: TextStyle(color: Colors.white))),
              const PopupMenuItem(
                  value: 'RESOLVED',
                  child:
                      Text('Resueltos', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(
                  value: 'CLOSED',
                  child: Text('Closed', style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _error != null
              ? _buildErrorView()
              : _filteredTickets.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadTickets,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredTickets.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildTicketCard(
                              _filteredTickets[index], index);
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
            decoration: BoxDecoration(
                color: darkCardBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[850]!)),
            child: Icon(Icons.confirmation_number_outlined,
                size: 64, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          Text(
            'No se encontraron tickets',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: lightText),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus solicitudes aparecerán aquí.',
            style: TextStyle(color: subText),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadTickets,
              child: const Text('Vuelve a intentarlo')),
        ],
      ),
    );
  }

  Widget _buildTicketCard(ContactMessage ticket, int index) {
    final statusColor = _getStatusColor(ticket.status);
    final icon = _getStatusIcon(ticket.status);

    return Material(
      color: darkCardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: statusColor, width: 4)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.grey), // Arrow color
          ),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

            // HEADER
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: statusColor, size: 20),
            ),
            title: Text(
              ticket.subject,
              style: TextStyle(fontWeight: FontWeight.bold, color: lightText),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Status: ${ticket.status.label}',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  _formatDate(ticket.createdAt),
                  style: TextStyle(color: subText, fontSize: 11),
                ),
              ],
            ),

            // BODY
            children: [
              // User Message Bubble
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[850]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu solicitud',
                          style: TextStyle(
                              color: subText,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(ticket.message,
                          style: TextStyle(color: Colors.grey[300])),
                    ],
                  ),
                ),
              ),

              // Context info if any
              if (ticket.songId != null || ticket.albumId != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          ticket.songId != null
                              ? Icons.music_note
                              : Icons.album,
                          size: 16,
                          color: Colors.purpleAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ticket.songId != null
                              ? 'Ref: Song #${ticket.songId}'
                              : 'Ref: Album #${ticket.albumId}',
                          style: TextStyle(
                              color: Colors.purple[100], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 8),

              // Responses Section
              _buildResponsesSection(ticket),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildResponsesSection(ContactMessage ticket) {
    return FutureBuilder<List<ContactResponse>>(
      future: _loadResponses(ticket.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))));
        }
        if (snapshot.hasError) {
          return Text('Error al cargar respuestas.',
              style: TextStyle(color: Colors.red[300], fontSize: 12));
        }

        final responses = snapshot.data ?? [];

        if (responses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: subText),
                const SizedBox(width: 8),
                Text('Sin respuestas.',
                    style: TextStyle(
                        color: subText,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Respuestas',
                  style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            ...responses.map((response) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                      bottomLeft: Radius.zero,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.support_agent,
                              size: 14, color: AppTheme.primaryBlue),
                          const SizedBox(width: 6),
                          Text('Asistente',
                              style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          const Spacer(),
                          Text(_formatDate(response.createdAt),
                              style: TextStyle(color: subText, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(response.response,
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  Future<List<ContactResponse>> _loadResponses(int ticketId) async {
    try {
      final response = await _contactService.getResponsesByMessageId(ticketId);
      if (response.success && response.data != null) {
        return response.data!
            .map((json) =>
                ContactResponse.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
