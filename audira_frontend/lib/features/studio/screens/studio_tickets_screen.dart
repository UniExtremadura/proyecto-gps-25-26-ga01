import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/contact_message.dart';
import '../../../core/models/contact_response.dart';
import '../../../core/models/contact_status.dart';
import '../../../core/api/services/contact_service.dart';
import '../../../core/providers/auth_provider.dart';

class StudioTicketsScreen extends StatefulWidget {
  const StudioTicketsScreen({super.key});

  @override
  State<StudioTicketsScreen> createState() => _StudioTicketsScreenState();
}

class _StudioTicketsScreenState extends State<StudioTicketsScreen> {
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

  // --- Lógica del Negocio (Intacta) ---

  List<ContactMessage> get _filteredTickets {
    if (_selectedFilter == 'ALL') return _tickets;
    final status = ContactStatus.fromString(_selectedFilter);
    return _tickets.where((t) => t.status == status).toList();
  }

  Color _getStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.pending:
        return AppTheme.warningOrange;
      case ContactStatus.inProgress:
        return AppTheme.primaryBlue;
      case ContactStatus.resolved:
        return AppTheme.successGreen;
      case ContactStatus.closed:
        return AppTheme.textGrey;
    }
  }

  IconData _getStatusIcon(ContactStatus status) {
    switch (status) {
      case ContactStatus.pending:
        return Icons.access_time_filled_rounded;
      case ContactStatus.inProgress:
        return Icons.autorenew_rounded;
      case ContactStatus.resolved:
        return Icons.check_circle_rounded;
      case ContactStatus.closed:
        return Icons.lock_rounded;
    }
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

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        elevation: 0,
        title: const Text('SOPORTE TÉCNICO',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
                color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
            tooltip: 'Recargar',
          ),
          _buildFilterMenu(),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppTheme.errorRed)))
              : _filteredTickets.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadTickets,
                      color: AppTheme.primaryBlue,
                      backgroundColor: AppTheme.cardBlack,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredTickets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final ticket = _filteredTickets[index];
                          return _buildTicketCard(ticket)
                              .animate(delay: (index * 50).ms)
                              .fadeIn()
                              .slideY(begin: 0.1, end: 0);
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
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded,
                size: 64, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 24),
          const Text('No tienes tickets',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Tus consultas de soporte aparecerán aquí',
              style: TextStyle(color: AppTheme.textGrey)),
        ],
      ),
    );
  }

  Widget _buildFilterMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
      color: AppTheme.surfaceBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => setState(() => _selectedFilter = value),
      itemBuilder: (context) => [
        _buildPopupItem('ALL', 'Todos'),
        _buildPopupItem('PENDING', 'Pendientes', color: AppTheme.warningOrange),
        _buildPopupItem('IN_PROGRESS', 'En proceso',
            color: AppTheme.primaryBlue),
        _buildPopupItem('RESOLVED', 'Resueltos', color: AppTheme.successGreen),
        _buildPopupItem('CLOSED', 'Cerrados', color: AppTheme.textGrey),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String text,
      {Color? color}) {
    final isSelected = _selectedFilter == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textGrey,
              size: 18),
          const SizedBox(width: 12),
          Text(text,
              style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textGrey)),
          if (color != null) ...[
            const Spacer(),
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
          ]
        ],
      ),
    );
  }

  Widget _buildTicketCard(ContactMessage ticket) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: AppTheme.textGrey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getStatusColor(ticket.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(ticket.status),
              color: _getStatusColor(ticket.status),
              size: 20,
            ),
          ),
          title: Text(
            ticket.subject,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Row(
              children: [
                Text(_formatDate(ticket.createdAt),
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 12)),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                      color: AppTheme.textGrey, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(ticket.status.label,
                    style: TextStyle(
                        color: _getStatusColor(ticket.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          children: [
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),

            // Mensaje Original
            _buildMessageBubble(ticket.message, isUser: true),

            // Relacionado con (Canción/Álbum)
            if (ticket.songId != null || ticket.albumId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Icon(ticket.songId != null ? Icons.music_note : Icons.album,
                        color: AppTheme.textGrey, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ticket.songId != null
                            ? 'Canción ID: ${ticket.songId}'
                            : 'Álbum ID: ${ticket.albumId}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textGrey),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Sección Respuestas
            _buildResponsesSection(ticket),
          ],
        ),
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
                  child: CircularProgressIndicator(strokeWidth: 2)));
        }

        final responses = snapshot.data ?? [];

        if (responses.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.warningOrange.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.hourglass_empty_rounded,
                    color: AppTheme.warningOrange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esperando respuesta del soporte...',
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.warningOrange),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('RESPUESTAS',
                  style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
            ...responses.map((response) => _buildMessageBubble(
                response.response,
                isUser: false,
                author: response.adminName,
                date: response.createdAt)),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(String message,
      {required bool isUser, String? author, DateTime? date}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Author Label
          if (!isUser && author != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.support_agent,
                      size: 14, color: AppTheme.primaryBlue),
                  const SizedBox(width: 4),
                  Text(author,
                      style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  if (date != null) ...[
                    const SizedBox(width: 8),
                    Text(_formatDate(date),
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 10)),
                  ]
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                  : AppTheme.surfaceBlack,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(12),
              ),
              border: Border.all(
                color: isUser
                    ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                    : Colors.white10,
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                  color: isUser ? Colors.white : Colors.grey[300],
                  fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Hoy ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (difference.inDays == 1) return 'Ayer';
    return '${date.day}/${date.month}';
  }
}
