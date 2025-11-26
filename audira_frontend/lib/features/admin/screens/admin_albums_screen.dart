// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/moderation_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/moderation_widgets.dart';

/// GA01-162: Pantalla de administración de Albumes con moderación
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

  // GA01-162: Aprobar Album
  // IMPORTANTE: Primero verifica que todas las canciones del Album estén aprobadas
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

    // Primero, mostrar diálogo con información de las canciones del Album
    final shouldProceed = await _showAlbumSongsDialog(album);

    if (shouldProceed != true) {
      return;
    }

    if (!currentContext.mounted) return;
    final result = await showApproveDialog(
      context: currentContext,
      itemName: album.name,
      itemType: 'Album',
    );

    if (result == true) {
      try {
        final response =
            await _moderationService.approveAlbum(album.id, adminId);

        if (response.success) {
          if (!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('Album "${album.name}" aprobado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAlbums();
        } else {
          if (!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Error al aprobar el Album'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!currentContext.mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Mostrar diálogo con las canciones del Album y su estado de moderación
  Future<bool?> _showAlbumSongsDialog(Album album) async {
    // Obtener las canciones del Album
    final songsResponse = await _musicService.getSongsByAlbum(album.id);

    if (!songsResponse.success || songsResponse.data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar canciones: ${songsResponse.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    final songs = songsResponse.data!;

    if (songs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este Album no tiene canciones'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }
    final unapprovedSongs =
        songs.where((song) => song.moderationStatus != 'APPROVED').toList();

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Canciones del Album "${album.name}"'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total de canciones: ${songs.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (unapprovedSongs.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Canciones no aprobadas: ${unapprovedSongs.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Debes aprobar primero todas las canciones del Album antes de poder aprobar el Album completo.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Divider(),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final isApproved = song.moderationStatus == 'APPROVED';
                    return ListTile(
                      leading: Icon(
                        isApproved ? Icons.check_circle : Icons.pending,
                        color: isApproved ? Colors.green : Colors.orange,
                      ),
                      title: Text(song.name),
                      subtitle: Text(
                        song.moderationStatus ?? 'PENDING',
                        style: TextStyle(
                          color: isApproved ? Colors.green : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          if (unapprovedSongs.isEmpty)
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: const Text('Continuar'),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'No se puede aprobar el Album hasta que todas las canciones estén aprobadas'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: const Text('Cerrar'),
            ),
        ],
      ),
    );
  }

  // GA01-162: Rechazar Album
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
      itemType: 'Album',
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
          if (!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('Album "${album.name}" rechazado'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadAlbums();
        } else {
          if (!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Error al rechazar el Album'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!currentContext.mounted) return;
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
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _musicService.deleteAlbum(albumId);
        if (response.success) {
          if (!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text('Album deleted successfully')),
          );
          _loadAlbums();
        } else {
          if (!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to delete album'),
            ),
          );
        }
      } catch (e) {
        if (!currentContext.mounted) return;
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Título y badge de estado
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                AppTheme.primaryBlue,
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
                                                  'Artista ID: ${album.artistId} • \$${album.price.toStringAsFixed(2)}',
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
                                          album
                                              .rejectionReason!.isNotEmpty) ...[
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
                                          // GA01-162: Botones de moderación para Albumes pendientes
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
                                              icon: const Icon(Icons.close,
                                                  size: 18),
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
                                            onPressed: () =>
                                                _showAlbumForm(album),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _deleteAlbum(album.id),
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
        title: Text(isEditing ? 'Edit Album' : 'Añadir New Album'),
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
            child: const Text('Cancelar'),
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
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }
}
