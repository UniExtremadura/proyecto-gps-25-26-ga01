import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/moderation_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/moderation_widgets.dart';

/// GA01-162: Pantalla de administración de álbumes con moderación
class AdminAlbumsScreen extends StatefulWidget {
  const AdminAlbumsScreen({super.key});

  @override
  State<AdminAlbumsScreen> createState() => _AdminAlbumsScreenState();
}

class _AdminAlbumsScreenState extends State<AdminAlbumsScreen> {
  final MusicService _musicService = MusicService();
  final ModerationService _moderationService = ModerationService();
  final TextEditingController _searchController = TextEditingController();

  List<Album> _albums = [];
  List<Album> _filteredAlbums = [];
  bool _isLoading = false;
  String? _error;

  // GA01-162: Filtro de moderación
  String _moderationFilter = 'all'; // all, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _musicService.getAllAlbums();
      if (response.success && response.data != null) {
        setState(() {
          _albums = response.data!;
          _filteredAlbums = _albums;
        });
      } else {
        setState(() => _error = response.error ?? 'Failed to load albums');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterAlbums(String query) {
    setState(() {
      var filtered = _albums;

      // GA01-162: Filtrar por estado de moderación
      if (_moderationFilter != 'all') {
        filtered = filtered.where((album) {
          switch (_moderationFilter) {
            case 'pending':
              return album.moderationStatus == 'PENDING';
            case 'approved':
              return album.moderationStatus == 'APPROVED';
            case 'rejected':
              return album.moderationStatus == 'REJECTED';
            default:
              return true;
          }
        }).toList();
      }

      // Filtrar por búsqueda
      if (query.isNotEmpty) {
        filtered = filtered
            .where((album) =>
                album.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }

      _filteredAlbums = filtered;
    });
  }

  void _applyModerationFilter(String filter) {
    setState(() {
      _moderationFilter = filter;
    });
    _filterAlbums(_searchController.text);
  }

  // GA01-162: Aprobar álbum
  Future<void> _approveAlbum(Album album) async {
    final currentContext = context;
    final authProvider = context.read<AuthProvider>();
    final adminId = authProvider.currentUser?.id;

    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Admin ID no disponible')),
      );
      return;
    }

    final result = await showApproveDialog(
      context: context,
      itemName: album.name,
      itemType: 'álbum',
    );

    if (result == true) {
      try {
        final response =
            await _moderationService.approveAlbum(album.id, adminId);

        if (response.success) {
          if(!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('Álbum "${album.name}" aprobado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAlbums();
        } else {
          if(!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Error al aprobar el álbum'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if(!currentContext.mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // GA01-162: Rechazar álbum
  Future<void> _rejectAlbum(Album album) async {
    final currentContext = context;
    final authProvider = context.read<AuthProvider>();
    final adminId = authProvider.currentUser?.id;

    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Admin ID no disponible')),
      );
      return;
    }

    final result = await showRejectDialog(
      context: context,
      itemName: album.name,
      itemType: 'álbum',
    );

    if (result != null && result['reason'] != null) {
      try {
        final response = await _moderationService.rejectAlbum(
          album.id,
          adminId,
          result['reason']!,
          notes: result['notes'],
        );

        if (response.success) {
          if(!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('Álbum "${album.name}" rechazado'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadAlbums();
        } else {
          if(!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Error al rechazar el álbum'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if(!currentContext.mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAlbum(int albumId) async {
    final currentContext = context;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Album'),
        content: const Text('Are you sure you want to delete this album?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _musicService.deleteAlbum(albumId);
        if (response.success) {
          if(!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text('Album deleted successfully')),
          );
          _loadAlbums();
        } else {
          if(!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to delete album'),
            ),
          );
        }
      } catch (e) {
        if(!currentContext.mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Albums'),
        actions: [
          // GA01-162: Filtro de moderación
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por estado de moderación',
            onSelected: _applyModerationFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'header',
                enabled: false,
                child: Text(
                  'ESTADO DE MODERACIÓN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    if (_moderationFilter == 'all')
                      const Icon(Icons.check, size: 20),
                    if (_moderationFilter != 'all') const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    const Text('Todos'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    if (_moderationFilter == 'pending')
                      const Icon(Icons.check, size: 20),
                    if (_moderationFilter != 'pending')
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    const Text('Pendientes'),
                    const SizedBox(width: 8),
                    const Icon(Icons.hourglass_empty,
                        size: 16, color: Colors.orange),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'approved',
                child: Row(
                  children: [
                    if (_moderationFilter == 'approved')
                      const Icon(Icons.check, size: 20),
                    if (_moderationFilter != 'approved')
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    const Text('Aprobados'),
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle,
                        size: 16, color: Colors.green),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rejected',
                child: Row(
                  children: [
                    if (_moderationFilter == 'rejected')
                      const Icon(Icons.check, size: 20),
                    if (_moderationFilter != 'rejected')
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    const Text('Rechazados'),
                    const SizedBox(width: 8),
                    const Icon(Icons.cancel, size: 16, color: Colors.red),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAlbumForm(null);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search albums...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterAlbums,
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!),
                            ElevatedButton(
                              onPressed: _loadAlbums,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredAlbums.isEmpty
                        ? const Center(child: Text('No albums found'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredAlbums.length,
                            itemBuilder: (context, index) {
                              final album = _filteredAlbums[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Título y badge de estado
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: AppTheme.primaryBlue,
                                            child: const Icon(Icons.album,
                                                color: Colors.white),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  album.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'Artist ID: ${album.artistId} • \$${album.price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // GA01-162: Badge de estado
                                          ModerationBadge(
                                            status: album.moderationStatus,
                                            compact: true,
                                          ),
                                        ],
                                      ),

                                      // GA01-162: Mostrar razón de rechazo si existe
                                      if (album.rejectionReason != null &&
                                          album.rejectionReason!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        RejectionReasonWidget(
                                          reason: album.rejectionReason!,
                                        ),
                                      ],

                                      const SizedBox(height: 12),

                                      // Botones de acción
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // GA01-162: Botones de moderación para álbumes pendientes
                                          if (album.moderationStatus ==
                                              'PENDING') ...[
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _approveAlbum(album),
                                              icon: const Icon(Icons.check,
                                                  size: 18),
                                              label: const Text('Aprobar'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _rejectAlbum(album),
                                              icon:
                                                  const Icon(Icons.close, size: 18),
                                              label: const Text('Rechazar'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: AppTheme.primaryBlue),
                                            onPressed: () => _showAlbumForm(album),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _deleteAlbum(album.id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: (index * 50).ms);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _showAlbumForm(Album? album) {
    final isEditing = album != null;
    final titleController = TextEditingController(text: album?.name ?? '');
    final priceController =
        TextEditingController(text: album?.price.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Album' : 'Add New Album'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Album Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Album title is required')),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing
                      ? 'Album updated successfully'
                      : 'Album created successfully'),
                ),
              );
              _loadAlbums();
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}
