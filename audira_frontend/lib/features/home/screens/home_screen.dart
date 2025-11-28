import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/featured_content_service.dart';
import '../../../core/api/services/discovery_service.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/models/genre.dart';
import '../../../core/models/featured_content.dart';
import '../../../core/models/recommended_song.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/audio_provider.dart';
import '../../common/widgets/song_card.dart';
import '../../common/widgets/album_card.dart';
import '../../common/widgets/genre_chip.dart';
import '../../common/widgets/recommended_song_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- MANTENEMOS TODA LA LÓGICA Y VARIABLES ORIGINALES ---
  final MusicService _musicService = MusicService();
  final FeaturedContentService _featuredService = FeaturedContentService();
  final DiscoveryService _discoveryService = DiscoveryService();

  List<Song> _featuredSongs = [];
  List<Album> _featuredAlbums = [];
  List<Genre> _genres = [];

  // GA01-117: Separate recommendation categories
  List<RecommendedSong> _byPurchasedGenres = [];
  List<RecommendedSong> _byPurchasedArtists = [];
  List<RecommendedSong> _byLikedSongs = [];
  List<RecommendedSong> _fromFollowedArtists = [];
  List<RecommendedSong> _trending = [];
  List<RecommendedSong> _newReleases = [];

  bool _isLoading = true;
  bool _hasFeaturedContent = false;
  bool _hasRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _featuredSongs = [];
      _featuredAlbums = [];
      _genres = [];
    });

    final featuredResponse = await _featuredService.getActiveFeaturedContent();

    if (featuredResponse.success &&
        featuredResponse.data != null &&
        featuredResponse.data!.isNotEmpty) {
      _hasFeaturedContent = true;
      await _loadFeaturedContent(featuredResponse.data!);
    } else {
      _hasFeaturedContent = false;
      await _loadDefaultContent();
    }

    final genresResponse = await _musicService.getAllGenres();
    if (genresResponse.success && genresResponse.data != null) {
      _genres = genresResponse.data!;
    }

    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.currentUser != null) {
        await _loadRecommendations(authProvider.currentUser!.id);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecommendations(int userId) async {
    try {
      final response = await _discoveryService.getRecommendations(userId);
      if (response.success && response.data != null) {
        final recommendations = response.data!;
        setState(() {
          _byPurchasedGenres = recommendations.byPurchasedGenres;
          _byPurchasedArtists = recommendations.byPurchasedArtists;
          _byLikedSongs = recommendations.byLikedSongs;
          _fromFollowedArtists = recommendations.fromFollowedArtists;
          _trending = recommendations.trending;
          _newReleases = recommendations.newReleases;

          _hasRecommendations = _byPurchasedGenres.isNotEmpty ||
              _byPurchasedArtists.isNotEmpty ||
              _byLikedSongs.isNotEmpty ||
              _fromFollowedArtists.isNotEmpty ||
              _trending.isNotEmpty ||
              _newReleases.isNotEmpty;
        });

        // Enriquecer datos de artistas en todas las recomendaciones
        await _enrichRecommendationsData();
      } else {
        setState(() => _hasRecommendations = false);
      }
    } catch (e) {
      setState(() => _hasRecommendations = false);
    }
  }

  Future<void> _enrichRecommendationsData() async {
    final Map<int, String> artistCache = {};

    // Enriquecer cada lista de recomendaciones
    _byPurchasedGenres =
        await _enrichRecommendationList(_byPurchasedGenres, artistCache);
    _byPurchasedArtists =
        await _enrichRecommendationList(_byPurchasedArtists, artistCache);
    _byLikedSongs = await _enrichRecommendationList(_byLikedSongs, artistCache);
    _fromFollowedArtists =
        await _enrichRecommendationList(_fromFollowedArtists, artistCache);
    _trending = await _enrichRecommendationList(_trending, artistCache);
    _newReleases = await _enrichRecommendationList(_newReleases, artistCache);

    if (mounted) {
      setState(() {}); // Actualizar UI con los nombres enriquecidos
    }
  }

  Future<List<RecommendedSong>> _enrichRecommendationList(
      List<RecommendedSong> songs, Map<int, String> artistCache) async {
    List<RecommendedSong> enrichedSongs = List.from(songs);

    for (int i = 0; i < enrichedSongs.length; i++) {
      final song = enrichedSongs[i];
      if (_needsEnrichment(song.artistName)) {
        final realName = await _fetchArtistName(song.artistId, artistCache);
        if (realName != null) {
          enrichedSongs[i] = song.copyWith(artistName: realName);
        }
      }
    }

    return enrichedSongs;
  }

  bool _needsEnrichment(String name) {
    return name == 'Artista Desconocido' ||
        name == 'Artista desconocido' ||
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

  Future<void> _loadFeaturedContent(
      List<FeaturedContent> featuredContent) async {
    final songIds = featuredContent
        .where((item) => item.contentType == FeaturedContentType.song)
        .map((item) => item.contentId)
        .toList();

    final albumIds = featuredContent
        .where((item) => item.contentType == FeaturedContentType.album)
        .map((item) => item.contentId)
        .toList();

    for (final songId in songIds) {
      final response = await _musicService.getSongById(songId);
      if (response.success && response.data != null) {
        _featuredSongs.add(response.data!);
      }
    }

    for (final albumId in albumIds) {
      final response = await _musicService.getAlbumById(albumId);
      if (response.success && response.data != null) {
        _featuredAlbums.add(response.data!);
      }
    }

    // Enriquecer nombres de artistas en canciones destacadas
    await _enrichFeaturedSongsData();
  }

  Future<void> _enrichFeaturedSongsData() async {
    final Map<int, String> artistCache = {};
    List<Song> enrichedSongs = List.from(_featuredSongs);
    bool needsUpdate = false;

    for (int i = 0; i < enrichedSongs.length; i++) {
      final song = enrichedSongs[i];
      if (_needsEnrichment(song.artistName)) {
        final realName = await _fetchArtistName(song.artistId, artistCache);
        if (realName != null) {
          enrichedSongs[i] = song.copyWith(artistName: realName);
          needsUpdate = true;
        }
      }
    }

    if (needsUpdate && mounted) {
      setState(() {
        _featuredSongs = enrichedSongs;
      });
    }
  }

  Future<void> _loadDefaultContent() async {
    final songsResponse = await _musicService.getTopPublishedSongs();
    final albumsResponse = await _musicService.getRecentPublishedAlbums();

    if (songsResponse.success && songsResponse.data != null) {
      _featuredSongs = songsResponse.data!.take(10).toList();
    }

    if (albumsResponse.success && albumsResponse.data != null) {
      _featuredAlbums = albumsResponse.data!.take(10).toList();
    }

    // Enriquecer nombres de artistas
    await _enrichFeaturedSongsData();
  }

  // --- NUEVA UI: DISEÑO EPIC DARK ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Cargando minimalista en fondo negro
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryBlue,
        backgroundColor: AppTheme.surfaceBlack,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeroSection(),
            ),

            // 3. Géneros (Chips)
            if (_genres.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "EXPLORAR GÉNEROS",
                        style: TextStyle(
                          color: AppTheme.textDarkGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _genres.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GenreChip(genre: _genres[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Secciones de Recomendaciones (Renderizado Dinámico)
            if (_hasRecommendations) ...[
              if (_byPurchasedGenres.isNotEmpty)
                _buildSectionSliver(
                  title: 'Basado en tus Gustos',
                  subtitle: 'Porque te gusta este estilo',
                  icon: Icons.graphic_eq,
                  items: _byPurchasedGenres,
                ),
              if (_byPurchasedArtists.isNotEmpty)
                _buildSectionSliver(
                  title: 'Artistas Relacionados',
                  subtitle: 'Basado en tus compras recientes',
                  icon: Icons.person_outline,
                  items: _byPurchasedArtists,
                ),
              if (_byLikedSongs.isNotEmpty)
                _buildSectionSliver(
                  title: 'Tu Vibe Actual',
                  subtitle: 'Canciones similares a tus favoritos',
                  icon: Icons.favorite_border,
                  items: _byLikedSongs,
                  accentColor: Colors.pinkAccent,
                ),
              if (_fromFollowedArtists.isNotEmpty)
                _buildSectionSliver(
                  title: 'De Quienes Sigues',
                  subtitle: 'Novedades de tu red',
                  icon: Icons.people_outline,
                  items: _fromFollowedArtists,
                ),
              if (_trending.isNotEmpty)
                _buildSectionSliver(
                  title: 'Tendencias Globales',
                  subtitle: 'Lo que está sonando ahora',
                  icon: Icons.trending_up,
                  items: _trending,
                  accentColor: AppTheme.warningOrange,
                ),
              if (_newReleases.isNotEmpty)
                _buildSectionSliver(
                  title: 'Recién Salido',
                  subtitle: 'Nuevos lanzamientos esta semana',
                  icon: Icons.new_releases_outlined,
                  items: _newReleases,
                  accentColor: AppTheme.successGreen,
                ),
            ],

            // 5. Destacados Generales (Fallback o Adicional)
            if (_featuredSongs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      _buildSectionHeader(
                          'Selección Audira',
                          'Canciones elegidas para ti',
                          Icons.star_border,
                          AppTheme.primaryBlue),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _featuredSongs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SongCard(song: _featuredSongs[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_featuredAlbums.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120), // Espacio final
                  child: Column(
                    children: [
                      _buildSectionHeader(
                          'Álbumes Esenciales',
                          'Producciones completas destacadas',
                          Icons.album_outlined,
                          AppTheme.accentBlue),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _featuredAlbums.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: AlbumCard(album: _featuredAlbums[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          // Solo mostrar el FAB si hay una canción y el miniplayer está oculto
          if (audioProvider.currentSong != null &&
              !audioProvider.demoFinished &&
              !audioProvider.miniPlayerVisible) {
            return FloatingActionButton(
              onPressed: () {
                audioProvider.showMiniPlayer();
              },
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(Icons.music_note),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES DE DISEÑO ---

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "DESCUBRIMIENTO SEMANAL",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _hasFeaturedContent
                ? 'Sonidos que\nDefinen el Momento'
                : 'Explora el\nUniverso Sonoro',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w900,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actualizado diariamente para inspirarte.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildSectionSliver({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<dynamic> items,
    Color accentColor = AppTheme.primaryBlue,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title, subtitle, icon, accentColor),
            SizedBox(
              height: 240,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is RecommendedSong) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: RecommendedSongCard(song: item),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ).animate(delay: 200.ms).fadeIn(),
    );
  }

  // Header reutilizable para secciones
  Widget _buildSectionHeader(
      String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
