import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports de tu proyecto
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/song.dart';
import '../../../core/models/playlist.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../core/api/services/music_service.dart';
import '../../../config/theme.dart';
import 'song_selector_screen.dart';

class CreatePlaylistScreen extends StatefulWidget {
  final int? playlistId;

  const CreatePlaylistScreen({super.key, this.playlistId});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PlaylistService _playlistService = PlaylistService();

  bool _isPublic = false; // Mantenemos la variable aunque por defecto sea false
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

  // --- LÓGICA DE CARGA Y GUARDADO ---

  Future<void> _loadPlaylistData() async {
    setState(() => _isLoadingData = true);
    try {
      final response =
          await _playlistService.getPlaylistWithSongs(widget.playlistId!);
      if (response.success && response.data != null) {
        _originalPlaylist = response.data?['playlist'];
        List<Song> tempSongs = response.data?['songs'] ?? [];
        _nameController.text = _originalPlaylist!.name;
        _descriptionController.text = _originalPlaylist!.description ?? '';
        _isPublic = _originalPlaylist!.isPublic;

        setState(() {
          _selectedSongs = tempSongs;
        });

        // Enriquecer datos del artista
        await _enrichSongData(tempSongs);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error cargando playlist: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _enrichSongData(List<Song> songs) async {
    bool needsUpdate = false;
    final Map<int, String> artistCache = {};

    List<Song> enrichedSongs = List.from(songs);
    for (int i = 0; i < enrichedSongs.length; i++) {
      final s = enrichedSongs[i];
      if (_needsEnrichment(s.artistName)) {
        final realName = await _fetchArtistName(s.artistId, artistCache);
        if (realName != null) {
          enrichedSongs[i] = s.copyWith(artistName: realName);
          needsUpdate = true;
        }
      }
    }

    if (needsUpdate && mounted) {
      setState(() {
        _selectedSongs = enrichedSongs;
      });
    }
  }

  bool _needsEnrichment(String name) {
    return name == 'Artista Desconocido' ||
        name.startsWith('Artist #') ||
        name.startsWith('Artista #') ||
        name.startsWith('user');
  }

  Future<String?> _fetchArtistName(int artistId, Map<int, String> cache) async {
    if (cache.containsKey(artistId)) return cache[artistId];

    try {
      final response = await MusicService().getArtistById(artistId);
      if (response.success && response.data != null) {
        final artist = response.data!;
        final name = artist.artistName ?? artist.displayName;
        cache[artistId] = name;
        return name;
      }
    } catch (e) {
      debugPrint("Error fetching artist $artistId: $e");
    }
    return null;
  }

  Future<void> _savePlaylist() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final libraryProvider = context.read<LibraryProvider>();

      if (!authProvider.isAuthenticated) {
        throw Exception('Inicia sesión primero');
      }

      if (widget.playlistId == null) {
        // CREAR
        final playlist = await libraryProvider.createPlaylist(
          userId: authProvider.currentUser!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isPublic: _isPublic,
        );

        if (playlist != null) {
          for (final song in _selectedSongs) {
            await libraryProvider.addSongToPlaylist(playlist.id, song.id);
          }
          if (mounted) {
            _showSnackBar('Playlist creada');
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('Error al crear playlist');
        }
      } else {
        // ACTUALIZAR
        await libraryProvider.updatePlaylist(
          playlistId: widget.playlistId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isPublic: _isPublic,
        );
        if (mounted) {
          _showSnackBar('Playlist actualizada');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePlaylist() async {
    final currentContext = context;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        title: const Text('Eliminar Playlist',
            style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro? No se puede deshacer.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.playlistId != null) {
      setState(() => _isLoading = true);
      try {
        if (!currentContext.mounted) return;
        await currentContext
            .read<LibraryProvider>()
            .deletePlaylist(widget.playlistId!);
        if (mounted) {
          _showSnackBar('Playlist eliminada');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) _showSnackBar('Error: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSongsToPlaylist() async {
    final currentContext = context;
    final currentSongIds = _selectedSongs.map((s) => s.id).toList();
    final result = await Navigator.push<List<Song>>(
      context,
      MaterialPageRoute(
        builder: (_) => SongSelectorScreen(
          currentSongIds: currentSongIds,
          playlistName: _nameController.text.isEmpty
              ? 'Nueva Playlist'
              : _nameController.text,
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (widget.playlistId != null) {
        // Si editamos, guardamos directo
        setState(() => _isLoading = true);
        try {
          if (!currentContext.mounted) return;
          final lib = currentContext.read<LibraryProvider>();
          for (final s in result) {
            await lib.addSongToPlaylist(widget.playlistId!, s.id);
          }
          await _loadPlaylistData();
          if (mounted) _showSnackBar('${result.length} canciones añadidas');
        } catch (e) {
          if (mounted) _showSnackBar('Error: $e', isError: true);
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        // Si creamos, solo actualizamos lista local
        setState(() => _selectedSongs.addAll(result));
      }
    }
  }

  Future<void> _removeSong(Song song) async {
    if (widget.playlistId != null) {
      setState(() => _isLoading = true);
      try {
        await context
            .read<LibraryProvider>()
            .removeSongFromPlaylist(widget.playlistId!, song.id);
        await _loadPlaylistData();
        if (mounted) _showSnackBar('Canción eliminada');
      } catch (e) {
        if (mounted) _showSnackBar('Error: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      setState(() => _selectedSongs.remove(song));
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
            widget.playlistId == null ? 'Nueva Playlist' : 'Editar Playlist'),
        actions: [
          IconButton(
            icon: Icon(
                _showPreview ? Icons.edit_note : Icons.remove_red_eye_outlined),
            tooltip: _showPreview ? 'Editar' : 'Vista Previa',
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
          if (widget.playlistId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
              onPressed: _deletePlaylist,
            ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildEditor(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COVER PLACEHOLDER (Estético)
            Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBlack,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10))
                  ],
                  border: Border.all(color: Colors.white10),
                ),
                child: const Center(
                  child: Icon(Icons.playlist_play_rounded,
                      size: 64, color: AppTheme.primaryBlue),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            ),

            const SizedBox(height: 32),

            // INPUTS
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Nombre',
                labelStyle: TextStyle(color: AppTheme.textGrey),
                filled: true,
                fillColor: AppTheme.surfaceBlack,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                prefixIcon:
                    const Icon(Icons.title, color: AppTheme.primaryBlue),
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Mínimo 3 caracteres'
                  : null,
            ).animate().fadeIn().slideX(),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Descripción (Opcional)',
                labelStyle: TextStyle(color: AppTheme.textGrey),
                filled: true,
                fillColor: AppTheme.surfaceBlack,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                alignLabelWithHint: true,
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(),

            const SizedBox(height: 32),

            // SONGS HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Canciones (${_selectedSongs.length})',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                TextButton.icon(
                  onPressed: _isLoading ? null : _addSongsToPlaylist,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Añadir'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 12),

            // SONGS LIST
            if (_selectedSongs.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white10, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.queue_music, size: 48, color: Colors.white24),
                    SizedBox(height: 8),
                    Text('Lista vacía',
                        style: TextStyle(color: Colors.white38)),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms)
            else
              ..._selectedSongs.asMap().entries.map((entry) {
                final index = entry.key;
                final song = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    tileColor: AppTheme.surfaceBlack,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(song.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(song.artistName,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white54)),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppTheme.errorRed),
                      onPressed: () => _removeSong(song),
                    ),
                  ),
                ).animate().fadeIn(delay: (50 * index).ms).slideX();
              }),

            const SizedBox(height: 100), // Espacio para el bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // PREVIEW CARD
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.playlist_play_rounded,
                    size: 80, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  _nameController.text.isEmpty
                      ? 'Sin Título'
                      : _nameController.text,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                if (_descriptionController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _descriptionController.text,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Badge(
                        icon: Icons.music_note,
                        text: '${_selectedSongs.length} Canciones'),
                    const SizedBox(width: 12),
                    const _Badge(icon: Icons.lock_outline, text: 'Privada'),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().scale(),

          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Vista Previa de Canciones",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(height: 16),

          if (_selectedSongs.isEmpty)
            const Text("No hay canciones añadidas.",
                style: TextStyle(color: Colors.white54))
          else
            ..._selectedSongs.map((s) => ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.white54),
                  title:
                      Text(s.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.artistName,
                      style: const TextStyle(color: Colors.white38)),
                  trailing: Text(s.durationFormatted,
                      style: const TextStyle(color: Colors.white38)),
                )),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        border:
            Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.white)),
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
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.playlistId == null
                            ? 'Crear Playlist'
                            : 'Guardar',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Badge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
