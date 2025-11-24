import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:async';
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

  List<Song> _songs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Genre> _availableGenres = [];
  List<RecommendedSong> _recommendedSongs = [];

  bool _isLoading = false;
  bool _isLoadingMoreSongs = false;
  bool _isLoadingMoreAlbums = false;
  bool _hasSearched = false;
  bool _hasRecommendations = false;
  late TabController _tabController;

  int _currentSongPage = 0;
  int _currentAlbumPage = 0;
  int? _selectedGenreId;
  bool _hasMoreSongs = false;
  bool _hasMoreAlbums = false;
  String _currentQuery = '';
  String _selectedSort = 'recent';
  Timer? _debounceTimer;

  // NUEVO: Variables para rango de precio
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

  Future<void> _loadTrendingContent() async {
    setState(() => _isLoading = true);
    try {
      // Solo mostrar contenido publicado en el buscador
      final songsResponse = await _musicService.getTopPublishedSongs();
      final albumsResponse = await _musicService.getRecentPublishedAlbums();

      if (songsResponse.success && songsResponse.data != null) {
        _songs = songsResponse.data!.take(10).toList();
      }
      if (albumsResponse.success && albumsResponse.data != null) {
        _albums = albumsResponse.data!.take(10).toList();
      }

      // GA01-117: Load personalized recommendations if user is authenticated
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          await _loadRecommendations(authProvider.currentUser!.id);
        }
      }
    } catch (e) {
      debugPrint('Error loading trending content: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// GA01-117: Load personalized recommendations for the user
  Future<void> _loadRecommendations(int userId) async {
    try {
      final response = await _discoveryService.getRecommendations(userId);

      if (response.success && response.data != null) {
        final recommendations = response.data!;

        // Get all recommendations from all categories
        _recommendedSongs =
            recommendations.getAllRecommendations().take(10).toList();
        _hasRecommendations = _recommendedSongs.isNotEmpty;
      } else {
        _hasRecommendations = false;
      }
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
      _hasRecommendations = false;
    }
  }

  Future<void> _performSearch(String query) async {
    final currentContext = context;

    // Si no hay query ni filtros, cargar trending
    if (query.trim().isEmpty && _selectedGenreId == null && _minPrice == null && _maxPrice == null) {
      setState(() {
        _isLoading = true;
        _hasSearched = false;
        _songs = [];
        _albums = [];
        _artists = [];
        _currentSongPage = 0;
        _currentAlbumPage = 0;
        _hasMoreSongs = false;
        _hasMoreAlbums = false;
        _currentQuery = '';
      });
      _loadTrendingContent();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _currentQuery = query;
      _currentSongPage = 0;
      _currentAlbumPage = 0;
    });

    try {
      if (_tabController.index == 0 || _tabController.index == 1) {
        final songResponse = await _discoveryService.searchSongs(
          query,
          page: 0,
          genreId: _selectedGenreId,
          sortBy: _selectedSort,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
        );
        if (songResponse.success && songResponse.data != null) {
          final data = songResponse.data as Map<String, dynamic>;
          setState(() {
            _songs = data['songs'] as List<Song>;
            _hasMoreSongs = data['hasMore'] as bool;
          });
        }
      }

      if (_tabController.index == 0 || _tabController.index == 2) {
        final albumResponse = await _discoveryService.searchAlbums(
          query,
          page: 0,
          genreId: _selectedGenreId,
          sortBy: _selectedSort,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
        );
        if (albumResponse.success && albumResponse.data != null) {
          final data = albumResponse.data as Map<String, dynamic>;
          setState(() {
            _albums = data['albums'] as List<Album>;
            _hasMoreAlbums = data['hasMore'] as bool;
          });
        }
      }

      _artists = [];
    } catch (e) {
      debugPrint('Search error: $e');
      if(!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreSongs() async {
    setState(() => _isLoadingMoreSongs = true);
    try {
      final nextPage = _currentSongPage + 1;
      final response = await _discoveryService.searchSongs(
        _currentQuery,
        page: nextPage,
        genreId: _selectedGenreId,
        sortBy: _selectedSort,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final newSongs = data['songs'] as List<Song>;
        if (mounted) {
          setState(() {
            _songs.addAll(newSongs);
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
      final response = await _discoveryService.searchAlbums(
        _currentQuery,
        page: nextPage,
        genreId: _selectedGenreId,
        sortBy: _selectedSort,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final newAlbums = data['albums'] as List<Album>;
        if (mounted) {
          setState(() {
            _albums.addAll(newAlbums);
            _currentAlbumPage = nextPage;
            _hasMoreAlbums = data['hasMore'] as bool;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingMoreAlbums = false);
    }
  }

  Future<void> _loadGenres() async {
    final response = await _discoveryService.getGenres();
    if (response.success && response.data != null) {
      if (mounted) {
        setState(() {
          _availableGenres = response.data!;
        });
      }
    }
  }

  void _showFilterBottomSheet() {
    // Sincronizar controllers con valores actuales
    _minPriceController.text = _minPrice?.toString() ?? '';
    _maxPriceController.text = _maxPrice?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrar y Ordenar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // SECCIÓN DE ORDENAMIENTO
                  const Text('Ordenar por:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStyledChip('Más Recientes', 'recent', setModalState),
                      _buildStyledChip('Más Antiguos', 'oldest', setModalState),
                      _buildStyledChip('Precio: Bajo', 'price_asc', setModalState),
                      _buildStyledChip('Precio: Alto', 'price_desc', setModalState),
                    ],
                  ),

                  const Divider(height: 30, color: Colors.grey),

                  // SECCIÓN DE RANGO DE PRECIO
                  const Text('Rango de Precio:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Mín',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixText: '\$ ',
                            prefixStyle: const TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              _minPrice = double.tryParse(value);
                            });
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('-', style: TextStyle(color: Colors.white, fontSize: 20)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Máx',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            prefixText: '\$ ',
                            prefixStyle: const TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              _maxPrice = double.tryParse(value);
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 30, color: Colors.grey),

                  // SECCIÓN DE GÉNEROS
                  const Text('Filtrar por Género:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 10),
                  _availableGenres.isEmpty
                      ? const Text("Cargando géneros...", style: TextStyle(color: Colors.white54))
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableGenres.map((genre) {
                                final isSelected = _selectedGenreId == genre.id;
                                return ChoiceChip(
                                  label: Text(genre.name),
                                  selected: isSelected,
                                  selectedColor: Colors.blue,
                                  backgroundColor: Colors.grey[800],
                                  labelStyle: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (bool selected) {
                                    setModalState(() {
                                      _selectedGenreId = selected ? genre.id : null;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                  const SizedBox(height: 24),

                  // BOTONES DE ACCIÓN
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedSort = 'recent';
                              _selectedGenreId = null;
                              _minPrice = null;
                              _maxPrice = null;
                              _minPriceController.clear();
                              _maxPriceController.clear();
                            });
                            setState(() {
                              _selectedSort = 'recent';
                              _selectedGenreId = null;
                              _minPrice = null;
                              _maxPrice = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Limpiar', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Actualizar estado padre antes de cerrar
                            setState(() {
                              _minPrice = double.tryParse(_minPriceController.text);
                              _maxPrice = double.tryParse(_maxPriceController.text);
                            });
                            Navigator.pop(context);
                            _performSearch(_searchController.text);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStyledChip(String label, String value, StateSetter setModalState) {
    final isSelected = _selectedSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey[800],
      labelStyle: const TextStyle(color: Colors.white),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.blue : Colors.transparent),
      ),
      onSelected: (bool selected) {
        if (selected) {
          setModalState(() => _selectedSort = value);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search songs, albums, artists...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() {}),
                onSubmitted: _performSearch,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                onPressed: _showFilterBottomSheet,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_hasSearched) _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return TabBar(
      controller: _tabController,
      labelColor: AppTheme.primaryBlue,
      unselectedLabelColor: AppTheme.textSecondary,
      indicatorColor: AppTheme.primaryBlue,
      tabs: [
        Tab(text: 'All (${_songs.length + _albums.length + _artists.length})'),
        Tab(text: 'Songs (${_songs.length})'),
        Tab(text: 'Albums (${_albums.length})'),
        Tab(text: 'Artists (${_artists.length})'),
      ],
    );
  }

  Widget _buildContent() {
    if (!_hasSearched) return _buildTrendingSection();
    if (_songs.isEmpty && _albums.isEmpty && _artists.isEmpty) return _buildEmptyState();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllResults(),
        _buildSongsList(),
        _buildAlbumsList(),
        _buildArtistsList(),
      ],
    );
  }

  Widget _buildTrendingSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descubre',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),

          // GA01-117: Personalized Recommendations
          if (_hasRecommendations) ...[
            Row(
              children: [
                Icon(
                  Icons.stars,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recomendado para ti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recommendedSongs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: RecommendedSongCard(song: _recommendedSongs[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (_songs.isNotEmpty) ...[
            const Text('Trending Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._songs.map((song) => SongListItem(
              song: song,
              onTap: () => Navigator.pushNamed(context, '/song', arguments: song.id),
            )),
          ],
          if (_albums.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Trending Albums', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._albums.map((album) => AlbumListItem(
              album: album,
              onTap: () => Navigator.pushNamed(context, '/album', arguments: album.id),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppTheme.textGrey),
          const SizedBox(height: 16),
          const Text('No results found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Try searching with different keywords', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAllResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_songs.isNotEmpty) ...[
            const Text('Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._songs.take(5).map((song) => SongListItem(
              song: song,
              onTap: () => Navigator.pushNamed(context, '/song', arguments: song.id),
            )),
            if (_songs.length > 5)
              TextButton(onPressed: () => _tabController.animateTo(1), child: const Text('View all songs')),
            const SizedBox(height: 16),
          ],
          if (_albums.isNotEmpty) ...[
            const Text('Albums', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._albums.take(5).map((album) => AlbumListItem(
              album: album,
              onTap: () => Navigator.pushNamed(context, '/album', arguments: album.id),
            )),
            if (_albums.length > 5)
              TextButton(onPressed: () => _tabController.animateTo(2), child: const Text('View all albums')),
            const SizedBox(height: 16),
          ],
          if (_artists.isNotEmpty) ...[
            const Text('Artists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._artists.take(5).map((artist) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(artist.artistName ?? artist.username),
              onTap: () => Navigator.pushNamed(context, '/artist', arguments: artist.id),
            )),
            if (_artists.length > 5)
              TextButton(onPressed: () => _tabController.animateTo(3), child: const Text('View all artists')),
          ],
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    return ListView.builder(
      controller: _songsScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _songs.length + (_hasMoreSongs ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _songs.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
        }
        final song = _songs[index];
        return SongListItem(song: song, onTap: () => Navigator.pushNamed(context, '/song', arguments: song.id));
      },
    );
  }

  Widget _buildAlbumsList() {
    return ListView.builder(
      controller: _albumsScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _albums.length + (_hasMoreAlbums ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _albums.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
        }
        final album = _albums[index];
        return AlbumListItem(album: album, onTap: () => Navigator.pushNamed(context, '/album', arguments: album.id));
      },
    );
  }

  Widget _buildArtistsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(artist.artistName ?? artist.username),
          subtitle: artist.bio != null ? Text(artist.bio!) : null,
          onTap: () => Navigator.pushNamed(context, '/artist', arguments: artist.id),
        );
      },
    );
  }
}