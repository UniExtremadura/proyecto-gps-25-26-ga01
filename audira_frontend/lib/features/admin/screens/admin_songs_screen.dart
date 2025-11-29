// ignore_for_file: use_build_context_synchronously

import 'package:audira_frontend/features/studio/screens/edit_song_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/moderation_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/moderation_widgets.dart';

/// GA01-162: Pantalla de administración de canciones con moderación
class AdminSongsScreen extends StatefulWidget {
  const AdminSongsScreen({super.key});

  @override
  State<AdminSongsScreen> createState() => _AdminSongsScreenState();
}

class _AdminSongsScreenState extends State<AdminSongsScreen> {
  final MusicService _musicService = MusicService();
  final ModerationService _moderationService = ModerationService();
  final TextEditingController _searchController = TextEditingController();

  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = false;
  String? _error;

  // GA01-162: Filtro de moderación
  String _moderationFilter = 'all'; // all, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _musicService.getAllSongs();
      if (response.success && response.data != null) {
        setState(() {
          _songs = response.data!;
          _filteredSongs = _songs;
        });
      } else {
        setState(
            () => _error = response.error ?? 'Fallo al cargar las canciones');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterSongs(String query) {
    setState(() {
      var filtered = _songs;

      // GA01-162: Filtrar por estado de moderación
      if (_moderationFilter != 'all') {
        filtered = filtered.where((song) {
          switch (_moderationFilter) {
            case 'pending':
              return song.moderationStatus == 'PENDING';
            case 'approved':
              return song.moderationStatus == 'APPROVED';
            case 'rejected':
              return song.moderationStatus == 'REJECTED';
            default:
              return true;
          }
        }).toList();
      }

      // Filtrar por búsqueda
      if (query.isNotEmpty) {
        filtered = filtered
            .where((song) =>
                song.name.toLowerCase().contains(query.toLowerCase()) ||
                (song.description
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false))
            .toList();
      }

      _filteredSongs = filtered;
    });
  }

  void _applyModerationFilter(String filter) {
    setState(() {
      _moderationFilter = filter;
    });
    _filterSongs(_searchController.text);
  }

  // GA01-162: Aprobar canción
  Future<void> _approveSong(Song song) async {
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
      itemName: song.name,
      itemType: 'canción',
    );

    if (result == true) {
      try {
        final response = await _moderationService.approveSong(song.id, adminId);

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Canción "${song.name}" aprobada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSongs();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Error al aprobar la canción'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // GA01-162: Rechazar canción
  Future<void> _rejectSong(Song song) async {
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
      itemName: song.name,
      itemType: 'canción',
    );

    if (result != null && result['reason'] != null) {
      try {
        final response = await _moderationService.rejectSong(
          song.id,
          adminId,
          result['reason']!,
          notes: result['notes'],
        );

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Canción "${song.name}" rechazada'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadSongs();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Error al rechazar la canción'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSong(int songId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar canción'),
        content: const Text(
            '¿Estás seguro de que quieres borrar esta canción? Esta acción es irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _musicService.deleteSong(songId);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Canción borrada exitosamente')),
          );
          _loadSongs();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Fallo al borrar la canción'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Canciones'),
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
                    const Text('Todas'),
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
                    const Text('Aprobadas'),
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
                    const Text('Rechazadas'),
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
              _showSongForm(null);
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
                hintText: 'Buscar canciones...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _filterSongs,
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
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSongs,
                              child: const Text('Volver a intentar'),
                            ),
                          ],
                        ),
                      )
                    : _filteredSongs.isEmpty
                        ? const Center(
                            child: Text('Sin canciones'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredSongs.length,
                            itemBuilder: (context, index) {
                              final song = _filteredSongs[index];
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
                                            child: const Icon(Icons.music_note,
                                                color: Colors.white),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  song.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'ID del artista: ${song.artistId} • \$${song.price.toStringAsFixed(2)}',
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
                                            status: song.moderationStatus,
                                            compact: true,
                                          ),
                                        ],
                                      ),

                                      // GA01-162: Mostrar razón de rechazo si existe
                                      if (song.rejectionReason != null &&
                                          song.rejectionReason!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        RejectionReasonWidget(
                                          reason: song.rejectionReason!,
                                        ),
                                      ],

                                      const SizedBox(height: 12),

                                      // Botones de acción
                                      Wrap(
                                        alignment: WrapAlignment.end,
                                        spacing: 4,
                                        runSpacing: 8,
                                        children: [
                                          // GA01-162: Botones de moderación para canciones pendientes
                                          if (song.moderationStatus ==
                                              'PENDING') ...[
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _approveSong(song),
                                              icon: const Icon(Icons.check,
                                                  size: 16),
                                              label: const Text('Aprobar',
                                                  style:
                                                      TextStyle(fontSize: 13)),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.green,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _rejectSong(song),
                                              icon: const Icon(Icons.close,
                                                  size: 16),
                                              label: const Text('Rechazar',
                                                  style:
                                                      TextStyle(fontSize: 13)),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                              ),
                                            ),
                                          ],
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: AppTheme.primaryBlue,
                                                size: 20),
                                            onPressed: () async {
                                              await Navigator.push<bool>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditSongScreen(
                                                          song: song),
                                                ),
                                              );
                                            },
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red, size: 20),
                                            onPressed: () {
                                              _deleteSong(song.id);
                                            },
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(
                                    delay: (index * 50).ms,
                                  );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _showSongForm(Song? song) {
    final isEditing = song != null;
    final nameController = TextEditingController(text: song?.name ?? '');
    final descriptionController =
        TextEditingController(text: song?.description ?? '');
    final priceController =
        TextEditingController(text: song?.price.toString() ?? '');
    final durationController =
        TextEditingController(text: song?.duration.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar canción' : 'Añadir una canción'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duración (segundos)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              descriptionController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nombre necesario')),
                );
                return;
              }

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEditing
                      ? 'Canción actualizada exitosamente'
                      : 'Canción creada exitosamente'),
                ),
              );

              _loadSongs();
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }
}
