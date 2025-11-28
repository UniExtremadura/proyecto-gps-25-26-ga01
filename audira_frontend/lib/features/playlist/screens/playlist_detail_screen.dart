import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Imports de tu proyecto
import '../../../config/theme.dart';
import '../../../core/models/playlist.dart';
import '../../../core/models/song.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../core/providers/library_provider.dart';
import 'song_selector_screen.dart';
import 'create_playlist_screen.dart'; // Importante para editar

class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlaylistService _playlistService = PlaylistService();

  Playlist? _playlist;
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await _playlistService.getPlaylistWithSongs(widget.playlistId);
      if (response.success && response.data != null) {
        if (mounted) {
          List<Song> tempSongs = response.data?['songs'] ?? [];
          setState(() {
            _playlist = response.data?['playlist'];
            _songs = tempSongs;
          });

          // Enriquecer datos del artista
          await _enrichSongData(tempSongs);
        }
      } else {
        if (mounted) {
          setState(() => _error = response.error ?? 'Failed to load playlist');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        _songs = enrichedSongs;
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

  // --- ACTIONS ---

  Future<void> _addSongsToPlaylist() async {
    final currentContext = context;
    if (_playlist == null) return;
    final currentSongIds = _songs.map((s) => s.id).toList();

    final List<Song>? selectedSongs = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongSelectorScreen(
          currentSongIds: currentSongIds,
          playlistName: _playlist!.name,
        ),
      ),
    );

    if (selectedSongs != null && selectedSongs.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        if (!currentContext.mounted) return;
        final libraryProvider = currentContext.read<LibraryProvider>();
        for (final song in selectedSongs) {
          await libraryProvider.addSongToPlaylist(widget.playlistId, song.id);
        }
        await _loadPlaylist();
        if (mounted) {
          _showSnackBar('${selectedSongs.length} canciones añadidas');
        }
      } catch (e) {
        if (mounted) _showSnackBar('Error: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        title: const Text('Eliminar canción',
            style: TextStyle(color: Colors.white)),
        content: Text('¿Quitar "${song.name}" de la lista?',
            style: const TextStyle(color: Colors.white70)),
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

    if (confirmed == true) {
      try {
        await _playlistService.removeSongFromPlaylist(
            widget.playlistId, song.id);
        _showSnackBar('Canción eliminada');
        _loadPlaylist(); // Recargar lista
      } catch (e) {
        _showSnackBar('Error: $e', isError: true);
      }
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
        content: const Text('Esta acción es irreversible.',
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

    if (confirmed == true) {
      try {
        if (!currentContext.mounted) return;
        await currentContext
            .read<LibraryProvider>()
            .deletePlaylist(widget.playlistId);
        if (mounted) {
          _showSnackBar('Playlist eliminada');
          Navigator.pop(context); // Volver atrás
        }
      } catch (e) {
        if (mounted) _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _playPlaylist({bool shuffle = false}) {
    if (_songs.isEmpty) return;
    final audioProvider = context.read<AudioProvider>();
    final authProvider = context.read<AuthProvider>();

    // Si es shuffle, mezclamos una copia local antes de enviar
    List<Song> queue = List.from(_songs);
    if (shuffle) queue.shuffle();

    audioProvider.playQueue(
      queue,
      startIndex: 0,
      isUserAuthenticated: authProvider.isAuthenticated,
      userId: authProvider.currentUser?.id,
    );
    Navigator.pushNamed(context, '/playback');
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isOwner =
        _playlist != null && authProvider.currentUser?.id == _playlist!.userId;

    if (_isLoading && _playlist == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    if (_error != null || _playlist == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
            child: Text(_error ?? 'Error desconocido',
                style: const TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(isOwner),
          _buildPlaylistHeader(),
          _buildActionButtons(),
          _buildSongList(isOwner),
          const SliverToBoxAdapter(
              child: SizedBox(height: 100)), // Espacio final
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              onPressed: _addSongsToPlaylist,
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(Icons.add_rounded, size: 32),
            ).animate().scale(delay: 500.ms)
          : null,
    );
  }

  Widget _buildSliverAppBar(bool isOwner) {
    return SliverAppBar(
      backgroundColor: AppTheme.backgroundBlack,
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
              color: Colors.black26, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () => Share.share(
              'Escucha mi playlist "${_playlist!.name}" en Audira!'),
        ),
        if (isOwner)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: const Color(0xFF2C2C2C),
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CreatePlaylistScreen(playlistId: widget.playlistId)),
                ).then((_) => _loadPlaylist());
              } else if (value == 'delete') {
                _deletePlaylist();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar',
                      style: TextStyle(color: AppTheme.errorRed))),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo abstracto generado
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.6),
                    AppTheme.backgroundBlack,
                  ],
                ),
              ),
            ),
            // Blur para suavizar
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
            // Portada central
            Center(
              child: Hero(
                tag: 'playlist-${_playlist!.id}',
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBlack,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: _playlist!.coverImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: _playlist!.coverImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.playlist_play_rounded,
                          size: 80, color: Colors.white24),
                ),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(
              _playlist!.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
            if (_playlist!.description != null &&
                _playlist!.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _playlist!.description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge(Icons.music_note, '${_songs.length} canciones'),
                const SizedBox(width: 12),
                _buildBadge(_playlist!.isPublic ? Icons.public : Icons.lock,
                    _playlist!.isPublic ? 'Pública' : 'Privada'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _playPlaylist(shuffle: false),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text("Reproducir"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _playPlaylist(shuffle: true),
                icon: const Icon(Icons.shuffle_rounded),
                label: const Text("Aleatorio"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(bool isOwner) {
    if (_songs.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(40),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(Icons.library_music_outlined,
                  size: 60, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text("Aún no hay canciones",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = _songs[index];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Text(
              '${index + 1}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            title: Text(
              song.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artistName,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            trailing: isOwner
                ? IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        color: Colors.white.withValues(alpha: 0.3), size: 20),
                    onPressed: () => _removeSong(song),
                  )
                : Text(song.durationFormatted,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12)),
            onTap: () {
              // Play queue starting from this song
              final audioProvider = context.read<AudioProvider>();
              final authProvider = context.read<AuthProvider>();
              audioProvider.playQueue(
                _songs,
                startIndex: index,
                isUserAuthenticated: authProvider.isAuthenticated,
                userId: authProvider.currentUser?.id,
              );
              Navigator.pushNamed(context, '/playback');
            },
          ).animate(delay: (30 * index).ms).fadeIn().slideX(begin: 0.1);
        },
        childCount: _songs.length,
      ),
    );
  }
}
