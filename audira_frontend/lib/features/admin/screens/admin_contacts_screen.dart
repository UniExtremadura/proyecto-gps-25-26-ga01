import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/contact_message.dart';
import '../../../core/models/contact_response.dart';
import '../../../core/models/contact_status.dart';
import '../../../core/api/services/contact_service.dart';
import '../../../core/providers/auth_provider.dart';

class AdminContactsScreen extends StatefulWidget {
  const AdminContactsScreen({super.key});

  @override
  State<AdminContactsScreen> createState() => _AdminContactsScreenState();
}

class _AdminContactsScreenState extends State<AdminContactsScreen> {
  final ContactService _contactService = ContactService();

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<ContactMessage> _contacts = [];
  bool _isLoading = false;
  String? _error;

  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _contactService.getAllContactMessages();

      if (response.success && response.data != null) {
        setState(() {
          _contacts = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Error loading messages';
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

  List<ContactMessage> get _filteredContacts {
    if (_selectedFilter == 'ALL') return _contacts;
    // Mapeo manual simple para coincidir con el enum o string del backend
    try {
      final status = ContactStatus.values.firstWhere((e) =>
          e.toString().split('.').last.toUpperCase() == _selectedFilter ||
          e.value == _selectedFilter);
      return _contacts.where((c) => c.status == status).toList();
    } catch (e) {
      return _contacts;
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    // Calcular métricas
    final int pendingCount =
        _contacts.where((c) => c.status == ContactStatus.pending).length;
    final int resolvedCount =
        _contacts.where((c) => c.status == ContactStatus.resolved).length;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('Support Inbox',
            style: TextStyle(
                color: AppTheme.primaryBlue, fontWeight: FontWeight.w800)),
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
              onPressed: _loadContacts,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. HEADER STATS
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: darkBg,
            child: Row(
              children: [
                Expanded(
                    child: _buildMiniStat('Pending', pendingCount.toString(),
                        Icons.mark_email_unread, Colors.orangeAccent)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildMiniStat('Resolved', resolvedCount.toString(),
                        Icons.task_alt, Colors.greenAccent)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildMiniStat('Total', _contacts.length.toString(),
                        Icons.inbox, Colors.blueGrey)),
              ],
            ),
          ).animate().slideY(begin: -0.2, end: 0, duration: 300.ms),

          // 2. FILTROS (CHIPS)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('PENDING', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('IN_PROGRESS', 'In Progress'),
                const SizedBox(width: 8),
                _buildFilterChip('RESOLVED', 'Resolved'),
                const SizedBox(width: 8),
                _buildFilterChip('CLOSED', 'Closed'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. LISTA
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryBlue))
                : _error != null
                    ? _buildErrorState()
                    : _filteredContacts.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                            itemCount: _filteredContacts.length,
                            separatorBuilder: (c, i) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildContactCard(
                                  _filteredContacts[index], index);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildMiniStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Text(value,
                  style: TextStyle(
                      color: lightText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: subText, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
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

  Widget _buildContactCard(ContactMessage contact, int index) {
    final statusColor = _getStatusColor(contact.status);
    final bool hasContext = contact.songId != null || contact.albumId != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: darkCardBg, // Usamos Material para el fondo
        borderRadius: BorderRadius.circular(16),
        clipBehavior:
            Clip.antiAlias, // Recorta el contenido al borde redondeado
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left:
                  BorderSide(color: statusColor, width: 4), // Indicador lateral
            ),
          ),
          child: Theme(
            // Forzamos el tema oscuro para este widget específico para que la flecha y textos sean claros
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.grey),
              textTheme: const TextTheme(
                titleMedium: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white),
              ),
            ),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

              // --- HEADER (Título y Badges) ---
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      contact.subject,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Blanco explícito
                          fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasContext) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('CONTEXT',
                          style: TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    )
                  ]
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(contact.name,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_formatDate(contact.createdAt),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 4),
                      Text(contact.status.label.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),

              // --- BODY EXPANDIDO ---
              children: [
                // Mensaje del usuario
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.black26, // Fondo más oscuro para el mensaje
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade800)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MESSAGE',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(contact.message,
                          style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 14) // Gris claro explícito
                          ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Contexto (Canción/Album)
                if (hasContext)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.deepPurple.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            contact.songId != null
                                ? Icons.music_note
                                : Icons.album,
                            color: Colors.purpleAccent,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('RELATED CONTENT',
                                  style: TextStyle(
                                      color: Colors.purpleAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                contact.songId != null
                                    ? 'Song ID: ${contact.songId}'
                                    : 'Album ID: ${contact.albumId}',
                                style: TextStyle(
                                    color: Colors.purple[100], fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                // Historial de respuestas
                _buildResponsesSection(contact),

                const SizedBox(height: 16),

                // Botones de Acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionButton(
                        icon: Icons.edit,
                        label: 'Status',
                        color: Colors.blueGrey,
                        onTap: () => _showStatusDialog(contact)),
                    const SizedBox(width: 8),
                    _ActionButton(
                        icon: Icons.reply,
                        label: 'Reply',
                        color: AppTheme.primaryBlue,
                        onTap: () => _showReplyDialog(contact)),
                    const SizedBox(width: 8),
                    _ActionButton(
                        icon: Icons.delete,
                        label: 'Delete',
                        color: Colors.redAccent,
                        onTap: () => _deleteContact(contact),
                        isOutlined: true),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsesSection(ContactMessage contact) {
    return FutureBuilder<List<ContactResponse>>(
      future: _loadResponses(contact.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))));
        }
        final responses = snapshot.data ?? [];
        if (responses.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('HISTORY',
                  style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            ...responses.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                    border: Border(
                        left: BorderSide(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                            width: 2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r.adminName,
                              style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          Text(_formatDate(r.createdAt),
                              style: TextStyle(color: subText, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r.response,
                          style:
                              TextStyle(color: Colors.grey[300], fontSize: 13)),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  // --- LOGIC HELPERS ---

  Future<List<ContactResponse>> _loadResponses(int contactId) async {
    try {
      final response = await _contactService.getResponsesByMessageId(contactId);
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

  // --- DIALOGS (DARK MODE) ---

  Future<void> _showReplyDialog(ContactMessage contact) async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser!;
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: Text('Reply to ${contact.name}',
            style: TextStyle(color: lightText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: TextStyle(color: lightText),
              decoration: InputDecoration(
                hintText: 'Type your response...',
                hintStyle: TextStyle(color: subText),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                final response = await _contactService.createResponse(
                  contactMessageId: contact.id,
                  adminId: currentUser.id,
                  adminName: currentUser.fullName,
                  response: controller.text.trim(),
                );
                if (response.success && context.mounted) {
                  Navigator.pop(context, true);
                }
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Response sent'), backgroundColor: Colors.green));
      _loadContacts();
    }
  }

  Future<void> _showStatusDialog(ContactMessage contact) async {
    ContactStatus? selected = contact.status;
    final result = await showDialog<ContactStatus>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: Text('Update Status', style: TextStyle(color: lightText)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: ContactStatus.values
                .map((status) => RadioListTile<ContactStatus>(
                      title: Text(status.label,
                          style: TextStyle(color: lightText)),
                      value: status,
                      groupValue: selected,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (val) => setState(() => selected = val),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selected),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && result != contact.status) {
      await _contactService.updateMessageStatus(contact.id, result.value);
      _loadContacts();
    }
  }

  Future<void> _deleteContact(ContactMessage contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCardBg,
        title: Text('Delete Message', style: TextStyle(color: lightText)),
        content: Text('Are you sure you want to delete this message?',
            style: TextStyle(color: subText)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await _contactService.deleteContactMessage(contact.id);
      _loadContacts();
    }
  }

  // --- UTILS ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text('No messages found',
              style: TextStyle(color: subText, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[900]),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadContacts, child: const Text('Retry')),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Widget auxiliar para botones de acción uniformes
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isOutlined;

  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap,
      this.isOutlined = false});

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
