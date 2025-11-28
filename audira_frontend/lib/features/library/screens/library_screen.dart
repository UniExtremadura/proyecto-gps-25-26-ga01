import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/download_provider.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/models/genre.dart';
import '../../../core/models/playlist.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/models/downloaded_song.dart';

enum SortCriterion { name, date }

enum SortOrder { asc, desc }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PlaylistService _playlistService = PlaylistService();
  final MusicService _musicService = MusicService();

  // Estado de Datos
  List<Playlist> _playlists = [];
  List<Genre> _availableGenres = [];
  bool _isLoadingPlaylists = true;
  bool _isLoadingGenres = true;

  // Estado de Filtros y Búsqueda
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<int> _selectedGenreIds = [];
  bool _showGenreFilter = false;

  // Estado de Ordenación
  SortCriterion _currentSortCriterion = SortCriterion.name;
  SortOrder _currentSortOrder = SortOrder.asc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging && mounted) {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
        _selectedGenreIds.clear();
        _showGenreFilter = false;
        _currentSortCriterion = SortCriterion.name;
        _currentSortOrder = SortOrder.asc;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.id;

      // Cargas paralelas de todos los datos necesarios
      await Future.wait([
        libraryProvider.loadLibrary(userId),
        libraryProvider
            .loadFavorites(userId), // <--- AGREGADA CARGA DE FAVORITOS
        _loadPlaylists(userId),
        _loadGenres(),
      ]);
    }
  }

  Future<void> _loadPlaylists(int userId) async {
    final response = await _playlistService.getUserPlaylists(userId);
    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          _playlists = response.data!;
        }
        _isLoadingPlaylists = false;
      });
    }
  }

  Future<void> _loadGenres() async {
    try {
      final response = await _musicService.getAllGenres();
      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _availableGenres = response.data!;
          }
          _isLoadingGenres = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading genres: $e");
      if (mounted) setState(() => _isLoadingGenres = false);
    }
  }

  List<T> _applyFiltersAndSort<T>(
    List<T> items,
    String Function(T) getName,
    String Function(T) getArtist,
    DateTime? Function(T) getDate,
  ) {
    if (items.isEmpty) return [];

    Iterable<T> filteredItems = items.where((item) {
      final query = _searchQuery.toLowerCase();
      final name = getName(item).toLowerCase();
      final artist = getArtist(item).toLowerCase();

      final matchesQuery =
          query.isEmpty || name.contains(query) || artist.contains(query);
      if (!matchesQuery) return false;

      if (_selectedGenreIds.isNotEmpty) {
        if (item is Song) {
          return item.genreIds.any((id) => _selectedGenreIds.contains(id));
        }
        if (item is Album) {
          return item.genreIds.any((id) => _selectedGenreIds.contains(id));
        }
        return true;
      }
      return true;
    }).toList();

    if (filteredItems.isNotEmpty) {
      filteredItems = filteredItems.toList()
        ..sort((a, b) {
          int comparison = 0;
          if (_currentSortCriterion == SortCriterion.name) {
            comparison =
                getName(a).toLowerCase().compareTo(getName(b).toLowerCase());
          } else if (_currentSortCriterion == SortCriterion.date) {
            final dateA = getDate(a);
            final dateB = getDate(b);
            if (dateA == null && dateB == null) {
              comparison = 0;
            } else if (dateA == null) {
              comparison = (_currentSortOrder == SortOrder.asc) ? 1 : -1;
            } else if (dateB == null) {
              comparison = (_currentSortOrder == SortOrder.asc) ? -1 : 1;
            } else {
              comparison = dateA.compareTo(dateB);
            }
          }
          return (_currentSortOrder == SortOrder.asc)
              ? comparison
              : -comparison;
        });
    }
    return filteredItems.toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentContext = context;
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopControlBar(),
            if (_showGenreFilter && _tabController.index != 2)
              _buildGenreFilterBar()
                  .animate()
                  .fadeIn()
                  .slideY(begin: -0.2, end: 0),
            Container(
              height: 48,
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppTheme.cardBlack, width: 1)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppTheme.primaryBlue,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textGrey,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: const [
                  Tab(text: 'CANCIONES'),
                  Tab(text: 'ÁLBUMES'),
                  Tab(text: 'PLAYLISTS'),
                  Tab(text: 'FAVORITOS'),
                  Tab(text: 'DESCARGAS'),
                ],
              ),
            ),
            Expanded(
              child: Consumer2<LibraryProvider, DownloadProvider>(
                builder: (context, libProvider, downProvider, child) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSongsList(libProvider.purchasedSongs),
                      _buildAlbumsList(libProvider.purchasedAlbums),
                      _buildPlaylistsList(),
                      // Verificamos si está cargando favoritos
                      libProvider.isFavoritesLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primaryBlue))
                          : _buildFavoritesList(libProvider),
                      _buildDownloadsList(downProvider.downloadedSongs),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: ValueListenableBuilder(
          valueListenable: _tabController.animation!,
          builder: (context, value, child) {
            return _tabController.index == 2
                ? FloatingActionButton.extended(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                          context, '/playlist/create');
                      if (result == true) {
                        if (!currentContext.mounted) return;
                        _loadPlaylists(Provider.of<AuthProvider>(currentContext,
                                listen: false)
                            .currentUser!
                            .id);
                      }
                    },
                    backgroundColor: AppTheme.primaryBlue,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Nueva Playlist"),
                  ).animate().scale()
                : const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildTopControlBar() {
    final hasActiveFilters =
        _searchQuery.isNotEmpty || _selectedGenreIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppTheme.cardBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: hasActiveFilters
                        ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                        : Colors.transparent),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle: TextStyle(
                      color: AppTheme.textGrey.withValues(alpha: 0.5)),
                  prefixIcon:
                      const Icon(Icons.search, color: AppTheme.textGrey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: AppTheme.textGrey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildIconButton(
            icon: Icons.filter_list_rounded,
            isActive: _showGenreFilter || _selectedGenreIds.isNotEmpty,
            onTap: () => setState(() => _showGenreFilter = !_showGenreFilter),
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: _currentSortOrder == SortOrder.asc
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            isActive: _currentSortCriterion == SortCriterion.date,
            onTap: _showSortMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildGenreFilterBar() {
    if (_isLoadingGenres) {
      return const LinearProgressIndicator(
          minHeight: 2, color: AppTheme.primaryBlue);
    }
    if (_availableGenres.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _availableGenres.length,
        itemBuilder: (context, index) {
          final genre = _availableGenres[index];
          final isSelected = _selectedGenreIds.contains(genre.id);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(genre.name),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  selected
                      ? _selectedGenreIds.add(genre.id)
                      : _selectedGenreIds.remove(genre.id);
                });
              },
              backgroundColor: AppTheme.cardBlack,
              selectedColor: AppTheme.primaryBlue,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textGrey,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none),
              padding: EdgeInsets.zero,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon,
      required bool isActive,
      required VoidCallback onTap}) {
    return Material(
      color: isActive ? AppTheme.primaryBlue : AppTheme.cardBlack,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 45,
          height: 45,
          alignment: Alignment.center,
          child: Icon(icon,
              color: isActive ? Colors.white : AppTheme.textGrey, size: 22),
        ),
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceBlack,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ORDENAR POR",
                style: TextStyle(
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 16),
            _buildSortOption('Nombre', SortCriterion.name),
            _buildSortOption('Fecha', SortCriterion.date),
            const Divider(color: AppTheme.cardBlack, height: 32),
            const Text("DIRECCIÓN",
                style: TextStyle(
                    color: AppTheme.textGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 16),
            _buildDirectionOption(
                'Ascendente (A-Z / Antiguo-Nuevo)', SortOrder.asc),
            _buildDirectionOption(
                'Descendente (Z-A / Nuevo-Antiguo)', SortOrder.desc),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, SortCriterion criterion) {
    final selected = _currentSortCriterion == criterion;
    return ListTile(
      title: Text(label,
          style: TextStyle(
              color: selected ? AppTheme.primaryBlue : Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      trailing: selected
          ? const Icon(Icons.check, color: AppTheme.primaryBlue)
          : null,
      onTap: () {
        setState(() => _currentSortCriterion = criterion);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildDirectionOption(String label, SortOrder order) {
    final selected = _currentSortOrder == order;
    return ListTile(
      title: Text(label,
          style:
              TextStyle(color: selected ? AppTheme.primaryBlue : Colors.white)),
      trailing: selected
          ? const Icon(Icons.check, color: AppTheme.primaryBlue)
          : null,
      onTap: () {
        setState(() => _currentSortOrder = order);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildSongsList(List<Song> songs) {
    final filtered = _applyFiltersAndSort<Song>(
        songs, (s) => s.name, (s) => s.artistName, (s) => s.createdAt);

    if (filtered.isEmpty) {
      return _buildEmptyState("canciones", Icons.music_note);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + 120),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final song = filtered[index];
        return _buildGenericTile(
          title: song.name,
          subtitle: song.artistName,
          icon: Icons.music_note,
          color: AppTheme.primaryBlue,
          trailing: Text('\$${song.price}',
              style: const TextStyle(
                  color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
          onTap: () =>
              Navigator.pushNamed(context, '/song', arguments: song.id),
        ).animate().fadeIn(delay: (30 * index).ms).slideX();
      },
    );
  }

  Widget _buildAlbumsList(List<Album> albums) {
    final filtered = _applyFiltersAndSort<Album>(
        albums, (a) => a.name, (a) => a.artistName, (a) => a.createdAt);

    if (filtered.isEmpty) return _buildEmptyState("álbumes", Icons.album);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + 120),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final album = filtered[index];
        return _buildGenericTile(
          title: album.name,
          subtitle: "${album.artistName} • ${album.createdAt?.year ?? '-'}",
          icon: Icons.album,
          color: Colors.purpleAccent,
          onTap: () =>
              Navigator.pushNamed(context, '/album', arguments: album.id),
        ).animate().fadeIn(delay: (30 * index).ms).slideX();
      },
    );
  }

  Widget _buildPlaylistsList() {
    final currentContext = context;
    if (_isLoadingPlaylists) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }

    final filtered = _applyFiltersAndSort<Playlist>(
        _playlists, (p) => p.name, (p) => '', (p) => p.createdAt);

    if (filtered.isEmpty && _searchQuery.isEmpty) {
      return _buildEmptyPlaylistState();
    }
    if (filtered.isEmpty) {
      return _buildEmptyState("playlists", Icons.queue_music);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + 120),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final playlist = filtered[index];
        return _buildGenericTile(
          title: playlist.name,
          subtitle:
              "${playlist.songCount} canciones • ${playlist.isPublic ? 'Pública' : 'Privada'}",
          icon: Icons.queue_music,
          color: AppTheme.accentBlue,
          onTap: () async {
            final res = await Navigator.pushNamed(context, '/playlist',
                arguments: playlist.id);
            if (res == true) {
              if (!currentContext.mounted) return;
              _loadPlaylists(
                  Provider.of<AuthProvider>(currentContext, listen: false)
                      .currentUser!
                      .id);
            }
          },
        ).animate().fadeIn(delay: (30 * index).ms).slideX();
      },
    );
  }

  Widget _buildFavoritesList(LibraryProvider libProvider) {
    final favSongs = _applyFiltersAndSort<Song>(libProvider.favoriteSongs,
        (s) => s.name, (s) => s.artistName, (s) => s.createdAt);
    final favAlbums = _applyFiltersAndSort<Album>(libProvider.favoriteAlbums,
        (a) => a.name, (a) => a.artistName, (a) => a.createdAt);

    if (favSongs.isEmpty && favAlbums.isEmpty) {
      return _buildEmptyState("favoritos", Icons.favorite_border);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + 120),
      children: [
        if (favSongs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("CANCIONES",
                style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5)),
          ),
          ...favSongs.map((s) => _buildGenericTile(
                title: s.name,
                subtitle: s.artistName,
                icon: Icons.favorite,
                color: AppTheme.errorRed,
                onTap: () =>
                    Navigator.pushNamed(context, '/song', arguments: s.id),
              )),
          const SizedBox(height: 16),
        ],
        if (favAlbums.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("ÁLBUMES",
                style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5)),
          ),
          ...favAlbums.map((a) => _buildGenericTile(
                title: a.name,
                subtitle: a.artistName,
                icon: Icons.album,
                color: Colors.white,
                onTap: () =>
                    Navigator.pushNamed(context, '/album', arguments: a.id),
              )),
        ]
      ],
    );
  }

  Widget _buildDownloadsList(List<DownloadedSong> downloads) {
    final filtered = _applyFiltersAndSort<DownloadedSong>(downloads,
        (d) => d.songName, (d) => d.artistName, (d) => d.downloadedAt);

    if (filtered.isEmpty) {
      return _buildEmptyState("descargas", Icons.download_done);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + 120),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final download = filtered[index];
        return _buildGenericTile(
          title: download.songName,
          subtitle: download.artistName,
          icon: Icons.download_done_rounded,
          color: AppTheme.successGreen,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
            onPressed: () =>
                Provider.of<DownloadProvider>(context, listen: false)
                    .deleteDownload(download.songId),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/downloads');
          },
        ).animate().fadeIn(delay: (30 * index).ms).slideX();
      },
    );
  }

  Widget _buildGenericTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: AppTheme.surfaceBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBlack),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            maxLines: 1,
            style: TextStyle(
                color: AppTheme.textGrey.withValues(alpha: 0.8), fontSize: 13)),
        trailing: trailing ??
            Icon(Icons.chevron_right,
                color: AppTheme.textGrey.withValues(alpha: 0.5), size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState(String type, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBlack,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 48, color: AppTheme.textGrey.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? "Sin resultados para '$_searchQuery'"
                : "No tienes $type",
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaylistState() {
    final currentContext = context;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music,
              size: 64, color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text("Crea tu primera playlist",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Organiza tu música a tu manera",
              style: TextStyle(color: AppTheme.textGrey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result =
                  await Navigator.pushNamed(context, '/playlist/create');
              if (result == true) {
                if (!currentContext.mounted) return;
                _loadPlaylists(
                    Provider.of<AuthProvider>(currentContext, listen: false)
                        .currentUser!
                        .id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add),
            label: const Text("Crear Ahora"),
          )
        ],
      ),
    );
  }
}
