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
  final MusicService _musicService = MusicService();
  final FeaturedContentService _featuredService = FeaturedContentService();
  final DiscoveryService _discoveryService = DiscoveryService();

  List<Song> _featuredSongs = [];
  List<Album> _featuredAlbums = [];
  List<Genre> _genres = [];
  List<RecommendedSong> _recommendedSongs = [];
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
      // Limpiar listas antes de recargar para evitar duplicación
      _featuredSongs = [];
      _featuredAlbums = [];
      _genres = [];
      _recommendedSongs = [];
    });

    // GA01-156, GA01-157: Cargar contenido destacado programado
    final featuredResponse = await _featuredService.getActiveFeaturedContent();

    if (featuredResponse.success &&
        featuredResponse.data != null &&
        featuredResponse.data!.isNotEmpty) {
      _hasFeaturedContent = true;
      await _loadFeaturedContent(featuredResponse.data!);
    } else {
      // Fallback: Si no hay contenido destacado, mostrar contenido por defecto
      _hasFeaturedContent = false;
      await _loadDefaultContent();
    }

    // Cargar géneros
    final genresResponse = await _musicService.getAllGenres();
    if (genresResponse.success && genresResponse.data != null) {
      _genres = genresResponse.data!;
    }

    // GA01-117: Cargar recomendaciones personalizadas si el usuario está autenticado
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.currentUser != null) {
        await _loadRecommendations(authProvider.currentUser!.id);
      }
    }

    setState(() => _isLoading = false);
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

    // Cargar canciones destacadas
    for (final songId in songIds) {
      final response = await _musicService.getSongById(songId);
      if (response.success && response.data != null) {
        _featuredSongs.add(response.data!);
      }
    }

    // Cargar álbumes destacados
    for (final albumId in albumIds) {
      final response = await _musicService.getAlbumById(albumId);
      if (response.success && response.data != null) {
        _featuredAlbums.add(response.data!);
      }
    }
  }

  Future<void> _loadDefaultContent() async {
    // Solo mostrar contenido publicado en la pantalla de inicio
    final songsResponse = await _musicService.getTopPublishedSongs();
    final albumsResponse = await _musicService.getRecentPublishedAlbums();

    if (songsResponse.success && songsResponse.data != null) {
      _featuredSongs = songsResponse.data!.take(10).toList();
    }

    if (albumsResponse.success && albumsResponse.data != null) {
      _featuredAlbums = albumsResponse.data!.take(10).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Section
          Text(
            _hasFeaturedContent
                ? 'Contenido destacado'
                : 'Descubre nueva música',
            style: Theme.of(context).textTheme.displaySmall,
          ).animate().fadeIn().slideY(),

          const SizedBox(height: 8),

          Text(
            _hasFeaturedContent
                ? 'Contenido seleccionado especialmente para ti'
                : 'Explora canciones y álbumes destacados',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textGrey,
                ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),

          // Genres
          if (_genres.isNotEmpty) ...[
            Text(
              'Géneros',
              style: Theme.of(context).textTheme.headlineMedium,
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
            const SizedBox(height: 32),
          ],

          // GA01-117: Personalized Recommendations
          if (_hasRecommendations) ...[
            Row(
              children: [
                Icon(
                  Icons.stars,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recomendado para ti',
                  style: Theme.of(context).textTheme.headlineMedium,
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
            const SizedBox(height: 32),
          ],

          // Featured Songs
          if (_featuredSongs.isNotEmpty) ...[
            Text(
              'Canciones destacadas',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
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
            const SizedBox(height: 32),
          ],

          // Featured Albums
          if (_featuredAlbums.isNotEmpty) ...[
            Text(
              'Últimos Lanzamientos',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.builder(
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
        ],
      ),
    );
  }
}
