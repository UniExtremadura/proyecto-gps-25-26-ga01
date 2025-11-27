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
          _error = response.error ?? 'Error al cargar mensajes';
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
    final status = ContactStatus.fromString(_selectedFilter);
    return _contacts.where((c) => c.status == status).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes de Contacto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContacts,
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
              const PopupMenuItem(value: 'IN_PROGRESS', child: Text('En proceso')),
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
                        onPressed: _loadContacts,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _filteredContacts.isEmpty
                  ? const Center(child: Text('No hay mensajes de contacto'))
                  : RefreshIndicator(
                      onRefresh: _loadContacts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(contact.status),
                                child: Icon(
                                  contact.status == ContactStatus.pending
                                      ? Icons.pending
                                      : contact.status == ContactStatus.inProgress
                                          ? Icons.sync
                                          : contact.status == ContactStatus.resolved
                                              ? Icons.check_circle
                                              : Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                contact.subject,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text('${contact.name} • ${contact.email}'),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (contact.songId != null || contact.albumId != null)
                                              ? Colors.purple.withValues(alpha: 0.2)
                                              : Colors.blue.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          (contact.songId != null || contact.albumId != null)
                                              ? 'ARTISTA'
                                              : 'USUARIO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: (contact.songId != null || contact.albumId != null)
                                                ? Colors.purple
                                                : Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${contact.status.label} • ${_formatDate(contact.createdAt)}',
                                    style: TextStyle(
                                      color: _getStatusColor(contact.status),
                                      fontSize: 12,
                                    ),
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
                                        'Mensaje:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(contact.message),
                                      const SizedBox(height: 16),
                                      // Mostrar contenido relacionado si existe
                                      if (contact.songId != null || contact.albumId != null) ...[
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
                                                contact.songId != null ? Icons.music_note : Icons.album,
                                                color: Colors.purple,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  contact.songId != null
                                                      ? 'Relacionado con canción ID: ${contact.songId}'
                                                      : 'Relacionado con álbum ID: ${contact.albumId}',
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
                                      _buildResponsesSection(contact),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          // 1. Cambiar estado (ElevatedButton) - Relleno y Compacto
                                          ElevatedButton.icon(
                                            onPressed: () => _showStatusDialog(contact),
                                            icon: const Icon(Icons.edit, size: 16),
                                            label: const Text('Estado', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              // Puedes elegir un color de fondo para el estado, aquí usamos un color neutral
                                              backgroundColor: Colors.green.shade300, 
                                              foregroundColor: Colors.white, // Color del texto/icono
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            ),
                                          ),
                                          const SizedBox(width: 4),

                                          // 2. Responder (ElevatedButton) - Relleno, Color Primario
                                          ElevatedButton.icon(
                                            onPressed: () => _showReplyDialog(contact),
                                            icon: const Icon(Icons.reply, size: 16),
                                            label: const Text('Responder', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryBlue, // Fondo azul
                                              foregroundColor: Colors.white, // Texto/icono blanco
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            ),
                                          ),
                                          const SizedBox(width: 4),

                                          // 3. Eliminar (ElevatedButton) - Relleno, Color de Peligro
                                          ElevatedButton.icon(
                                            onPressed: () => _deleteContact(contact),
                                            icon: const Icon(Icons.delete, size: 16),
                                            label: const Text('Eliminar', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red, // Fondo rojo
                                              foregroundColor: Colors.white, // Texto/icono blanco
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: (index * 50).ms);
                        },
                      ),
                    ),
    );
  }

  Widget _buildResponsesSection(ContactMessage contact) {
    return FutureBuilder<List<ContactResponse>>(
      future: _loadResponses(contact.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final responses = snapshot.data ?? [];

        if (responses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin respuestas aún',
              style: TextStyle(color: AppTheme.textGrey, fontStyle: FontStyle.italic),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Respuestas:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...responses.map((response) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            response.adminName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(response.createdAt),
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(response.response),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  Future<List<ContactResponse>> _loadResponses(int contactId) async {
    try {
      final response = await _contactService.getResponsesByMessageId(contactId);
      if (response.success && response.data != null) {
        return response.data!
            .map((json) => ContactResponse.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _showReplyDialog(ContactMessage contact) async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser!;
    final responseController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        title: const Text('Responder a ticket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: ${contact.name}'),
              const SizedBox(height: 4),
              Text('Asunto: ${contact.subject}'),
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                decoration: const InputDecoration(
                  labelText: 'Tu respuesta',
                  border: OutlineInputBorder(),
                  hintText: 'Escribe tu respuesta aquí...',
                ),
                maxLines: 6,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responseController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La respuesta no puede estar vacía'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                final response = await _contactService.createResponse(
                  contactMessageId: contact.id,
                  adminId: currentUser.id,
                  adminName: currentUser.fullName,
                  response: responseController.text.trim(),
                );

                if (response.success) {
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } else {
                  throw Exception(response.error ?? 'Error desconocido');
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Enviar respuesta'),
          ),
        ],
      ),
    );

    if (result == true) {
    if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Respuesta enviada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _loadContacts();
    }
  }

  Future<void> _showStatusDialog(ContactMessage contact) async {
    final currentContext = context;
    ContactStatus? selectedStatus = contact.status;

    final result = await showDialog<ContactStatus>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        title: const Text('Cambiar estado'),
        content: StatefulBuilder(
          builder: (context, setState) => RadioGroup(
            groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() => selectedStatus = value);
                },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ContactStatus.values.map((status) {
                return RadioListTile<ContactStatus>(
                  title: Text(status.label),
                  value: status,
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selectedStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && result != contact.status) {
      try {
        final response = await _contactService.updateMessageStatus(
          contact.id,
          result.value,
        );

        if (response.success) {
          if (!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(
              content: Text('Estado actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadContacts();
        } else {
          throw Exception(response.error ?? 'Error desconocido');
        }
      } catch (e) {
        if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteContact(ContactMessage contact) async {
    final currentContext = context;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: const Text('¿Estás seguro de que deseas eliminar este mensaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _contactService.deleteContactMessage(contact.id);

        if (response.success) {
          if(!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(
              content: Text('Mensaje eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadContacts();
        } else {
          throw Exception(response.error ?? 'Error desconocido');
        }
      } catch (e) {
        if(!currentContext.mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
