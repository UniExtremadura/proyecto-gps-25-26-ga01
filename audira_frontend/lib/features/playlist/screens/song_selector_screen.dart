import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

// Imports de tu proyecto
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/library_provider.dart';

class SongSelectorScreen extends StatefulWidget {
  final List<int> currentSongIds; // Canciones ya en la playlist
  final String playlistName;

  const SongSelectorScreen({
    super.key,
    this.currentSongIds = const [],
    required this.playlistName,
  });

  @override
  State<SongSelectorScreen> createState() => _SongSelectorScreenState();
}

class _SongSelectorScreenState extends State<SongSelectorScreen> {
  final MusicService _musicService = MusicService();
  final TextEditingController _searchController = TextEditingController();

  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  final Set<int> _selectedSongIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _musicService.getAllSongs();
      if (response.success && response.data != null) {
        // Obtener libraryProvider para filtrar solo canciones compradas
        if (!mounted) return;
        final libraryProvider = context.read<LibraryProvider>();

        // Filtrar canciones que NO están en la playlist Y que están compradas
        List<Song> tempSongs = response.data!
            .where((song) =>
                !widget.currentSongIds.contains(song.id) &&
                libraryProvider.isSongPurchased(song.id))
            .toList();

        setState(() {
          _allSongs = tempSongs;
          _filteredSongs = _allSongs;
        });

        // Enriquecer datos del artista
        await _enrichSongData(tempSongs);
      } else {
        _error = response.error ?? 'Error cargando canciones';
      }
    } catch (e) {
      _error = e.toString();
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
        _allSongs = enrichedSongs;
        _filteredSongs = _allSongs;
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
      final response = await _musicService.getArtistById(artistId);
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

  void _filterSongs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = _allSongs;
      } else {
        _filteredSongs = _allSongs.where((song) {
          return song.name.toLowerCase().contains(query.toLowerCase()) ||
              song.artistName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleSongSelection(int songId) {
    setState(() {
      if (_selectedSongIds.contains(songId)) {
        _selectedSongIds.remove(songId);
      } else {
        _selectedSongIds.add(songId);
      }
    });
  }

  void _confirmSelection() {
    final selectedSongs = _filteredSongs
        .where((song) => _selectedSongIds.contains(song.id))
        .toList();
    Navigator.pop(context, selectedSongs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Añadir canciones',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'a "${widget.playlistName}"',
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
        actions: [
          if (_selectedSongIds.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Añadir (${_selectedSongIds.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate().fadeIn().scale(),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSongs,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar canciones...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.search,
                    color: Colors.white.withValues(alpha: 0.4)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          _filterSongs('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
          ),

          // Selected count chip (opcional, ya está en AppBar, pero lo dejamos como resumen si se prefiere)
          // Se puede quitar si se siente redundante con el botón de AppBar.

          // Songs list
          Expanded(
            child: _buildSongsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllSongs,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue),
              child: const Text('Reintentar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_filteredSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty
                  ? Icons.music_note
                  : Icons.search_off,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay canciones disponibles'
                  : 'No se encontraron canciones',
              style: TextStyle(
                  fontSize: 18, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredSongs.length,
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        final isSelected = _selectedSongIds.contains(song.id);

        return GestureDetector(
          onTap: () => _toggleSongSelection(song.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                  : AppTheme.surfaceBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Cover Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: song.coverImageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[900]),
                          errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.music_note)),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                          child:
                              const Icon(Icons.music_note, color: Colors.white),
                        ),
                ),

                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color:
                              isSelected ? AppTheme.primaryBlue : Colors.white,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artistName,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Checkbox customizado
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected ? AppTheme.primaryBlue : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ).animate(delay: (index * 30).ms).fadeIn().slideX(begin: 0.1);
      },
    );
  }
}
