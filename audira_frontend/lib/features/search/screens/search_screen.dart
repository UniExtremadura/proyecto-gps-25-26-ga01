import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

// Imports de tu proyecto
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/models/genre.dart';
import '../../../core/models/artist.dart';
import '../../../core/models/recommended_song.dart';
import '../../../core/api/services/discovery_service.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../config/theme.dart';
import '../../common/widgets/song_list_item.dart';
import '../../common/widgets/album_list_item.dart';
import '../../common/widgets/recommended_song_card.dart';
import '../../common/widgets/mini_player.dart'; // Importante: MiniPlayer

enum SearchFilter { all, songs, albums, artists }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final DiscoveryService _discoveryService = DiscoveryService();
  final MusicService _musicService = MusicService();
  final ScrollController _songsScrollController = ScrollController();
  final ScrollController _albumsScrollController = ScrollController();

  // Data Sources
  List<Song> _songs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Genre> _availableGenres = [];

  // Recommendations
  List<RecommendedSong> _byPurchasedGenres = [];
  List<RecommendedSong> _byPurchasedArtists = [];
  List<RecommendedSong> _byLikedSongs = [];
  List<RecommendedSong> _fromFollowedArtists = [];
  List<RecommendedSong> _trending = [];
  List<RecommendedSong> _newReleases = [];

  // State flags
  bool _isLoading = false;
  bool _isLoadingMoreSongs = false;
  bool _isLoadingMoreAlbums = false;
  bool _hasSearched = false;
  bool _hasRecommendations = false;
  late TabController _tabController;

  // Pagination & Filtering
  int _currentSongPage = 0;
  int _currentAlbumPage = 0;
  int? _selectedGenreId;
  bool _hasMoreSongs = false;
  bool _hasMoreAlbums = false;
  String _currentQuery = '';
  String _selectedSort = 'recent';
  Timer? _debounceTimer;

  // Price Range
  double? _minPrice;
  double? _maxPrice;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTrendingContent();
    _songsScrollController.addListener(_onSongsScroll);
    _albumsScrollController.addListener(_onAlbumsScroll);
    _loadGenres();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _songsScrollController.dispose();
    _albumsScrollController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // --- SCROLL LISTENERS ---
  void _onSongsScroll() {
    if (_songsScrollController.position.pixels >=
            _songsScrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMoreSongs &&
        _hasMoreSongs) {
      _loadMoreSongs();
    }
  }

  void _onAlbumsScroll() {
    if (_albumsScrollController.position.pixels >=
            _albumsScrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMoreAlbums &&
        _hasMoreAlbums) {
      _loadMoreAlbums();
    }
  }

  // --- DATA LOADING LOGIC ---

  Future<void> _loadTrendingContent() async {
    setState(() => _isLoading = true);
    try {
      final songsResponse = await _musicService.getTopPublishedSongs();
      final albumsResponse = await _musicService.getRecentPublishedAlbums();

      if (songsResponse.success && songsResponse.data != null) {
        _songs = songsResponse.data!.take(10).toList();
      }
      if (albumsResponse.success && albumsResponse.data != null) {
        _albums = albumsResponse.data!.take(10).toList();
      }

      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          await _loadRecommendations(authProvider.currentUser!.id);
        }
      }
    } catch (e) {
      debugPrint('Error loading trending: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecommendations(int userId) async {
    try {
      final response = await _discoveryService.getRecommendations(userId);
      if (response.success && response.data != null) {
        final recs = response.data!;
        _byPurchasedGenres = recs.byPurchasedGenres;
        _byPurchasedArtists = recs.byPurchasedArtists;
        _byLikedSongs = recs.byLikedSongs;
        _fromFollowedArtists = recs.fromFollowedArtists;
        _trending = recs.trending;
        _newReleases = recs.newReleases;

        _hasRecommendations = [
          _byPurchasedGenres,
          _byPurchasedArtists,
          _byLikedSongs,
          _fromFollowedArtists,
          _trending,
          _newReleases
        ].any((list) => list.isNotEmpty);
      } else {
        _hasRecommendations = false;
      }
    } catch (e) {
      _hasRecommendations = false;
    }
  }

  Future<void> _loadGenres() async {
    final response = await _discoveryService.getGenres();
    if (response.success && response.data != null && mounted) {
      setState(() => _availableGenres = response.data!);
    }
  }

  // --- SEARCH LOGIC ---

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty &&
        _selectedGenreId == null &&
        _minPrice == null &&
        _maxPrice == null) {
      setState(() {
        _hasSearched = false;
        _songs = [];
        _albums = [];
        _artists = [];
        _currentQuery = '';
      });
      _loadTrendingContent();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    // Reset state for new search
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _currentQuery = query;
      _currentSongPage = 0;
      _currentAlbumPage = 0;
    });

    try {
      // 1. Songs
      if (_tabController.index <= 1) {
        final res = await _discoveryService.searchSongs(
          query,
          page: 0,
          genreId: _selectedGenreId,
          sortBy: _selectedSort,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
        );
        if (res.success && res.data != null) {
          final data = res.data as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _songs = data['songs'] as List<Song>;
              _hasMoreSongs = data['hasMore'] as bool;
            });
          }
        }
      }

      // 2. Albums
      if (_tabController.index == 0 || _tabController.index == 2) {
        final res = await _discoveryService.searchAlbums(
          query,
          page: 0,
          genreId: _selectedGenreId,
          sortBy: _selectedSort,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
        );
        if (res.success && res.data != null) {
          final data = res.data as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _albums = data['albums'] as List<Album>;
              _hasMoreAlbums = data['hasMore'] as bool;
            });
          }
        }
      }

      // 3. Artists
      final artistRes = await _discoveryService.searchArtists(query);
      if (artistRes.success && mounted) {
        setState(() => _artists = artistRes.data ?? []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreSongs() async {
    setState(() => _isLoadingMoreSongs = true);
    try {
      final nextPage = _currentSongPage + 1;
      final res = await _discoveryService.searchSongs(
        _currentQuery,
        page: nextPage,
        genreId: _selectedGenreId,
        sortBy: _selectedSort,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _songs.addAll(data['songs'] as List<Song>);
            _currentSongPage = nextPage;
            _hasMoreSongs = data['hasMore'] as bool;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingMoreSongs = false);
    }
  }

  Future<void> _loadMoreAlbums() async {
    setState(() => _isLoadingMoreAlbums = true);
    try {
      final nextPage = _currentAlbumPage + 1;
      final res = await _discoveryService.searchAlbums(
        _currentQuery,
        page: nextPage,
        genreId: _selectedGenreId,
        sortBy: _selectedSort,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _albums.addAll(data['albums'] as List<Album>);
            _currentAlbumPage = nextPage;
            _hasMoreAlbums = data['hasMore'] as bool;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingMoreAlbums = false);
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(),
              if (_hasSearched)
                SliverPersistentHeader(
                  delegate: _SliverTabBarDelegate(_buildFilterTabs()),
                  pinned: true,
                ),
            ],
            body: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryBlue))
                : _hasSearched
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllResults(),
                          _buildSongsList(),
                          _buildAlbumsList(),
                          _buildArtistsList(),
                        ],
                      )
                    : _buildTrendingSection(),
          ),

          // Mini Player siempre visible
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }

  // --- SLIVER APP BAR CON BÚSQUEDA ---
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF121212),
      floating: true,
      pinned: true,
      snap: true,
      elevation: 0,
      expandedHeight: 80, // Altura para la barra de búsqueda
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Buscar música, artistas...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _hasSearched = false;
                                });
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) {
                      setState(() {});
                      _onSearchChanged(val);
                    },
                    onSubmitted: _performSearch,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón de Filtro Estilizado
              GestureDetector(
                onTap: _showFilterBottomSheet,
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: const Color(0xFF121212),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryBlue,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        padding: EdgeInsets.zero,
        tabAlignment: TabAlignment.start,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        tabs: [
          const Tab(text: 'Todo'),
          Tab(text: 'Canciones (${_songs.length})'),
          Tab(text: 'Álbumes (${_albums.length})'),
          Tab(text: 'Artistas (${_artists.length})'),
        ],
      ),
    );
  }

  // --- VISTA DE TENDENCIAS (DEFAULT) ---
  Widget _buildTrendingSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección
          Text(
            "Descubre",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ).animate().fadeIn().slideX(),

          const SizedBox(height: 24),

          // Carruseles de Recomendaciones
          if (_hasRecommendations) ...[
            if (_newReleases.isNotEmpty)
              _buildHorizontalSection('Nuevos Lanzamientos', _newReleases,
                  Icons.new_releases_rounded),
            if (_trending.isNotEmpty)
              _buildHorizontalSection(
                  'Tendencias Globales', _trending, Icons.trending_up_rounded),
            if (_byLikedSongs.isNotEmpty)
              _buildHorizontalSection(
                  'Porque te gustó...', _byLikedSongs, Icons.favorite_rounded),
            if (_byPurchasedArtists.isNotEmpty)
              _buildHorizontalSection('De tus artistas', _byPurchasedArtists,
                  Icons.verified_rounded),
          ],

          // Listas estáticas si no hay recs
          if (_songs.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSectionHeader('Canciones Destacadas', null),
            const SizedBox(height: 10),
            ..._songs.take(5).map((s) => SongListItem(
                song: s,
                onTap: () =>
                    Navigator.pushNamed(context, '/song', arguments: s.id))),
          ],

          if (_albums.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Álbumes Populares', null),
            const SizedBox(height: 10),
            ..._albums.take(5).map((a) => AlbumListItem(
                album: a,
                onTap: () =>
                    Navigator.pushNamed(context, '/album', arguments: a.id))),
          ]
        ],
      ),
    );
  }

  Widget _buildHorizontalSection(
      String title, List<RecommendedSong> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, icon),
        const SizedBox(height: 12),
        SizedBox(
          height: 220, // Altura fija para las cards
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return RecommendedSongCard(song: items[index])
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (50 * index).ms)
                  .slideX();
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData? icon) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // --- RESULTADOS DE BÚSQUEDA ---

  Widget _buildAllResults() {
    if (_songs.isEmpty && _albums.isEmpty && _artists.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de Artistas (Círculos)
          if (_artists.isNotEmpty) ...[
            const Text("Artistas",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _artists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final artist = _artists[index];
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/artist',
                        arguments: artist.id),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: artist.profileImageUrl != null
                              ? NetworkImage(artist.profileImageUrl!)
                              : null,
                          child: artist.profileImageUrl == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 80,
                          child: Text(
                            artist.artistName ?? artist.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Canciones
          if (_songs.isNotEmpty) ...[
            const Text("Canciones",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 8),
            ..._songs.take(5).map((s) => SongListItem(
                  song: s,
                  onTap: () =>
                      Navigator.pushNamed(context, '/song', arguments: s.id),
                )),
            if (_songs.length > 5)
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text("Ver más canciones"),
              ),
            const SizedBox(height: 20),
          ],

          // Álbumes
          if (_albums.isNotEmpty) ...[
            const Text("Álbumes",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 8),
            ..._albums.take(5).map((a) => AlbumListItem(
                  album: a,
                  onTap: () =>
                      Navigator.pushNamed(context, '/album', arguments: a.id),
                )),
            if (_albums.length > 5)
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: const Text("Ver más álbumes"),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    if (_songs.isEmpty) return _buildEmptyState();
    return ListView.builder(
      controller: _songsScrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _songs.length + (_hasMoreSongs ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _songs.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return SongListItem(
          song: _songs[index],
          onTap: () => Navigator.pushNamed(context, '/song',
              arguments: _songs[index].id),
        ).animate().fadeIn(delay: (20 * (index % 10)).ms);
      },
    );
  }

  Widget _buildAlbumsList() {
    if (_albums.isEmpty) return _buildEmptyState();
    return ListView.builder(
      controller: _albumsScrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _albums.length + (_hasMoreAlbums ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _albums.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return AlbumListItem(
          album: _albums[index],
          onTap: () => Navigator.pushNamed(context, '/album',
              arguments: _albums[index].id),
        ).animate().fadeIn(delay: (20 * (index % 10)).ms);
      },
    );
  }

  Widget _buildArtistsList() {
    if (_artists.isEmpty) return _buildEmptyState();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _artists.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[800],
            backgroundImage: artist.profileImageUrl != null
                ? NetworkImage(artist.profileImageUrl!)
                : null,
            child: artist.profileImageUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          title: Text(artist.artistName ?? artist.username,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text("${artist.followerIds.length} seguidores",
              style: const TextStyle(color: Colors.grey)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.grey, size: 16),
          onTap: () =>
              Navigator.pushNamed(context, '/artist', arguments: artist.id),
        ).animate().fadeIn(delay: (20 * (index % 10)).ms);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            "No encontramos resultados",
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Intenta con otra palabra clave",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // --- FILTROS (BOTTOM SHEET) ---

  void _showFilterBottomSheet() {
    _minPriceController.text = _minPrice?.toString() ?? '';
    _maxPriceController.text = _maxPrice?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtros',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      TextButton(
                          onPressed: () {
                            // Reset Logic
                            setModalState(() {
                              _selectedSort = 'recent';
                              _selectedGenreId = null;
                              _minPrice = null;
                              _maxPrice = null;
                              _minPriceController.clear();
                              _maxPriceController.clear();
                            });
                          },
                          child: const Text("Reset",
                              style: TextStyle(color: AppTheme.primaryBlue)))
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Ordenar por',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildChip('Recientes', 'recent', setModalState),
                      _buildChip('Antiguos', 'oldest', setModalState),
                      _buildChip('Precio Bajo', 'price_asc', setModalState),
                      _buildChip('Precio Alto', 'price_desc', setModalState),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Precio',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildPriceInput(
                              _minPriceController, 'Min', setModalState, true)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("-",
                            style: TextStyle(color: Colors.grey, fontSize: 24)),
                      ),
                      Expanded(
                          child: _buildPriceInput(_maxPriceController, 'Max',
                              setModalState, false)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Género',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 12),
                  if (_availableGenres.isEmpty)
                    const Text("Cargando...",
                        style: TextStyle(color: Colors.grey))
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableGenres
                              .map((g) => ChoiceChip(
                                    label: Text(g.name),
                                    selected: _selectedGenreId == g.id,
                                    selectedColor: AppTheme.primaryBlue,
                                    backgroundColor: Colors.grey[800],
                                    labelStyle: TextStyle(
                                        color: _selectedGenreId == g.id
                                            ? Colors.white
                                            : Colors.grey[300]),
                                    onSelected: (sel) => setModalState(() =>
                                        _selectedGenreId = sel ? g.id : null),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide.none),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // Aplicar filtros al padre
                        setState(() {
                          _selectedSort = _selectedSort; // Ya está sync
                          _selectedGenreId = _selectedGenreId;
                          _minPrice = double.tryParse(_minPriceController.text);
                          _maxPrice = double.tryParse(_maxPriceController.text);
                        });
                        Navigator.pop(context);
                        _performSearch(_searchController.text); // Recargar
                      },
                      child: const Text("Aplicar Filtros",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, String value, StateSetter setModalState) {
    final isSelected = _selectedSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: Colors.grey[800],
      labelStyle:
          TextStyle(color: isSelected ? Colors.white : Colors.grey[300]),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      onSelected: (selected) {
        if (selected) setModalState(() => _selectedSort = value);
      },
    );
  }

  Widget _buildPriceInput(TextEditingController ctrl, String hint,
      StateSetter setModalState, bool isMin) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon:
            const Icon(Icons.attach_money, color: Colors.grey, size: 18),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onChanged: (val) {
        setModalState(() {
          if (isMin) {
            _minPrice = double.tryParse(val);
          } else {
            _maxPrice = double.tryParse(val);
          }
        });
      },
    );
  }
}

// Delegado simple para el TabBar pegajoso
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => 48.0;
  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      _tabBar;

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
