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
          _error = response.error ?? 'Error al cargar tickets';
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
    final status = ContactStatus.fromString(_selectedFilter);
    return _tickets.where((t) => t.status == status).toList();
  }

  Color _getStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.pending:
        return Colors.orange;
      case ContactStatus.inProgress:
        return Colors.blue;
      case ContactStatus.resolved:
        return Colors.green;
      case ContactStatus.closed:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ContactStatus status) {
    switch (status) {
      case ContactStatus.pending:
        return Icons.pending;
      case ContactStatus.inProgress:
        return Icons.sync;
      case ContactStatus.resolved:
        return Icons.check_circle;
      case ContactStatus.closed:
        return Icons.close;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
            tooltip: 'Recargar',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ALL', child: Text('Todos')),
              const PopupMenuItem(value: 'PENDING', child: Text('Pendientes')),
              const PopupMenuItem(
                  value: 'IN_PROGRESS', child: Text('En proceso')),
              const PopupMenuItem(value: 'RESOLVED', child: Text('Resueltos')),
              const PopupMenuItem(value: 'CLOSED', child: Text('Cerrados')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTickets,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _filteredTickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.inbox,
                              size: 64,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No tienes tickets',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tus consultas aparecerán aquí',
                            style: TextStyle(color: AppTheme.textGrey),
                          ),
                        ],
                      ).animate().fadeIn(),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTickets,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = _filteredTickets[index];
                          return _buildTicketCard(ticket)
                              .animate(delay: (index * 50).ms)
                              .fadeIn()
                              .slideY(begin: 0.1);
                        },
                      ),
                    ),
    );
  }

  Widget _buildTicketCard(ContactMessage ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(ticket.status),
          child: Icon(
            _getStatusIcon(ticket.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          ticket.subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Estado: ${ticket.status.label}',
              style: TextStyle(
                color: _getStatusColor(ticket.status),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _formatDate(ticket.createdAt),
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu consulta:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(ticket.message),
                const SizedBox(height: 16),
                // Mostrar contenido relacionado si existe
                if (ticket.songId != null || ticket.albumId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.purple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          ticket.songId != null ? Icons.music_note : Icons.album,
                          color: Colors.purple,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ticket.songId != null
                                ? 'Relacionado con canción ID: ${ticket.songId}'
                                : 'Relacionado con álbum ID: ${ticket.albumId}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                const SizedBox(height: 8),
                _buildResponsesSection(ticket),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsesSection(ContactMessage ticket) {
    return FutureBuilder<List<ContactResponse>>(
      future: _loadResponses(ticket.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text('Error al cargar respuestas: ${snapshot.error}');
        }

        final responses = snapshot.data ?? [];

        if (responses.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aún no hay respuestas. El equipo de soporte revisará tu consulta pronto.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Respuestas del equipo de soporte:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...responses.map((response) => _buildResponseItem(response)),
          ],
        );
      },
    );
  }

  Widget _buildResponseItem(ContactResponse response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryBlue,
                child: const Icon(Icons.support_agent,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.adminName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatDate(response.createdAt),
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(response.response),
        ],
      ),
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
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy a las ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer a las ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
