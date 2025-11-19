// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/song.dart';
import '../../../core/models/playlist.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../config/theme.dart';
import 'song_selector_screen.dart';

/// Pantalla para crear o editar playlists
/// GA01-113: Crear lista con nombre
class CreatePlaylistScreen extends StatefulWidget {
  final int? playlistId; // null = crear nueva

  const CreatePlaylistScreen({super.key, this.playlistId});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PlaylistService _playlistService = PlaylistService();

  bool _isPublic = false;
  bool _isLoading = false;
  bool _isLoadingData = false;
  bool _showPreview = false;

  Playlist? _originalPlaylist;
  List<Song> _selectedSongs = [];

  @override
  void initState() {
    super.initState();
    if (widget.playlistId != null) {
      _loadPlaylistData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Cargar datos de la playlist si estamos editando
  Future<void> _loadPlaylistData() async {
    setState(() => _isLoadingData = true);

    try {
      final response =
          await _playlistService.getPlaylistWithSongs(widget.playlistId!);
      if (response.success && response.data != null) {
        _originalPlaylist = response.data?['playlist'];
        _selectedSongs = response.data?['songs'] ?? [];

        _nameController.text = _originalPlaylist!.name;
        _descriptionController.text = _originalPlaylist!.description ?? '';
        _isPublic = _originalPlaylist!.isPublic;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar playlist: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  /// Guardar o actualizar playlist
  Future<void> _savePlaylist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final libraryProvider = context.read<LibraryProvider>();

      if (!authProvider.isAuthenticated) {
        throw Exception('Debes iniciar sesión para crear playlists');
      }

      if (widget.playlistId == null) {
        // CREAR NUEVA PLAYLIST
        final playlist = await libraryProvider.createPlaylist(
          userId: authProvider.currentUser!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isPublic: _isPublic,
        );

        if (playlist != null) {
          // Añadir canciones seleccionadas
          for (final song in _selectedSongs) {
            await libraryProvider.addSongToPlaylist(playlist.id, song.id);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Playlist "${playlist.name}" creada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('No se pudo crear la playlist');
        }
      } else {
        // EDITAR (se implementa en GA01-115)
        throw UnimplementedError('Edición disponible en GA01-115');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _togglePreview() {
    setState(() => _showPreview = !_showPreview);
  }

  /// Abrir pantalla de selección de canciones
  Future<void> _addSongsToPlaylist() async {
    final currentSongIds = _selectedSongs.map((s) => s.id).toList();
    final playlistName = _nameController.text.trim().isEmpty
        ? 'Nueva Playlist'
        : _nameController.text.trim();

    final List<Song>? selectedSongs = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongSelectorScreen(
          currentSongIds: currentSongIds,
          playlistName: playlistName,
        ),
      ),
    );

    if (selectedSongs != null && selectedSongs.isNotEmpty) {
      // Si estamos creando, añadir a la lista temporal
      setState(() {
        _selectedSongs.addAll(selectedSongs);
      });
    }
  }

  /// Eliminar canción de la playlist
  Future<void> _removeSong(Song song) async {
    setState(() {
      _selectedSongs.remove(song);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.playlistId == null ? 'Crear Playlist' : 'Editar Playlist',
        ),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: _togglePreview,
            tooltip: _showPreview ? 'Editar' : 'Vista previa',
          ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Playlist name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la Playlist',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.playlist_play),
                filled: true,
                fillColor: AppTheme.surfaceBlack,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                if (value.trim().length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppTheme.surfaceBlack,
              ),
              maxLines: 3,
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // Public/Private toggle
            Card(
              color: AppTheme.surfaceBlack,
              child: SwitchListTile(
                title: const Text('Playlist pública'),
                subtitle: const Text(
                    'Otros usuarios pueden ver y escuchar esta playlist'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() => _isPublic = value);
                },
                activeThumbColor: AppTheme.primaryBlue,
                secondary: Icon(
                  _isPublic ? Icons.public : Icons.lock,
                  color: _isPublic ? AppTheme.primaryBlue : AppTheme.textGrey,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Canciones',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_selectedSongs.length} ${_selectedSongs.length == 1 ? "canción" : "canciones"}',
                      style: const TextStyle(color: AppTheme.textGrey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addSongsToPlaylist,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 16),

// Selected songs list
            if (_selectedSongs.isEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.music_note,
                          size: 64,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay canciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca "Añadir" para seleccionar canciones',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms)
            else
              ..._selectedSongs.asMap().entries.map((entry) {
                final index = entry.key;
                final song = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: AppTheme.surfaceBlack,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(song.name),
                    subtitle: Text(
                      '${song.artistName} • ${song.durationFormatted}',
                      style: const TextStyle(color: AppTheme.textGrey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _removeSong(song),
                    ),
                  ),
                ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: -0.1);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.playlist_play,
                      size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _nameController.text.trim().isEmpty
                      ? 'Sin nombre'
                      : _nameController.text.trim(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_descriptionController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text.trim(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isPublic ? Icons.public : Icons.lock,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPublic ? 'Pública' : 'Privada',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 24),

          const Text(
            'Vista Previa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Así es como se verá tu playlist',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          if (_selectedSongs.isEmpty)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.music_note,
                      size: 64, color: AppTheme.textGrey),
                  const SizedBox(height: 16),
                  Text(
                    'No hay canciones en esta playlist',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          else
            ..._selectedSongs.asMap().entries.map((entry) {
              final index = entry.key;
              final song = entry.value;
              return Card(
                color: AppTheme.surfaceBlack,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(song.name),
                  subtitle: Text(
                    '${song.artistName} • ${song.durationFormatted}',
                  ),
                  trailing: const Icon(Icons.play_arrow),
                ),
              ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: -0.2);
            }),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        border: Border(
          top: BorderSide(color: AppTheme.textGrey.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePlaylist,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.playlistId == null
                            ? 'Crear Playlist'
                            : 'Guardar Cambios',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
