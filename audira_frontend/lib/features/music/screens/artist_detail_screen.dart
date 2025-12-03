import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports de tu proyecto
import 'package:audira_frontend/config/theme.dart';
import 'package:audira_frontend/core/api/services/music_service.dart';
import 'package:audira_frontend/core/api/services/user_service.dart';
import 'package:audira_frontend/core/models/album.dart';
import 'package:audira_frontend/core/models/artist.dart';
import 'package:audira_frontend/core/models/song.dart';
import 'package:audira_frontend/core/providers/auth_provider.dart';
import 'package:audira_frontend/features/common/widgets/mini_player.dart'; // Asegúrate de tener esto

class ArtistDetailScreen extends StatefulWidget {
  final int artistId;

  const ArtistDetailScreen({super.key, required this.artistId});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  final UserService _userService = UserService();

  Artist? _artist;
  List<Song> _songs = [];
  List<Album> _albums = [];

  bool _isLoading = true;
  String? _error;

  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadArtistDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artistResponse = await _musicService.getArtistById(widget.artistId);
      if (artistResponse.success && artistResponse.data != null) {
        _artist = artistResponse.data;

        final songsResponse =
            await _musicService.getSongsByArtist(widget.artistId);
        if (songsResponse.success && songsResponse.data != null) {
          _songs = songsResponse.data!;
        }

        final albumsResponse =
            await _musicService.getAlbumsByArtist(widget.artistId);
        if (albumsResponse.success && albumsResponse.data != null) {
          _albums = albumsResponse.data!;
        }
      } else {
        _error = artistResponse.error ?? 'Failed to load artist';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final authProvider = context.read<AuthProvider>();
    final currentContext = context;

    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para seguir artistas.')),
      );
      return;
    }

    final userId = authProvider.currentUser!.id;
    final targetId = widget.artistId;
    final isCurrentlyFollowing =
        authProvider.currentUser!.followingIds.contains(targetId);

    try {
      final response = isCurrentlyFollowing
          ? await _userService.unfollowUser(userId, targetId)
          : await _userService.followUser(userId, targetId);

      if (response.success && response.data != null) {
        authProvider.updateUser(response.data!);
        if (!currentContext.mounted) return;

        // Feedback visual sutil
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              !isCurrentlyFollowing
                  ? 'Siguiendo a ${_artist!.artistName ?? _artist!.username}'
                  : 'Dejaste de seguir',
            ),
            backgroundColor:
                !isCurrentlyFollowing ? AppTheme.successGreen : Colors.grey,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isFollowing =
        authProvider.currentUser?.followingIds.contains(widget.artistId) ??
            false;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    if (_error != null || _artist == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
            child: Text(_error ?? 'Artista no encontrado',
                style: const TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(isFollowing),
                SliverToBoxAdapter(child: _buildArtistStatsAndBio(isFollowing)),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(_buildTabBar()),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSongsTab(),
                _buildAlbumsTab(),
              ],
            ),
          ),

          // Mini Player Flotante
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

  // --- WIDGETS DE CABECERA ---

  Widget _buildSliverAppBar(bool isFollowing) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF121212).withValues(alpha: 0.9),
      expandedHeight: 380.0, // Altura grande para impacto visual
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration:
              BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. IMAGEN DE FONDO (BANNER)
            if (_artist!.bannerImageUrl != null)
              CachedNetworkImage(
                imageUrl: _artist!.bannerImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppTheme.surfaceBlack),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppTheme.primaryBlue, AppTheme.backgroundBlack],
                  ),
                ),
              ),

            // 2. DEGRADADO NEGRO (Para legibilidad)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black12,
                    Colors.black.withValues(alpha: 0.3),
                    const Color(0xFF121212), // Fusión perfecta con el fondo
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            // 3. CONTENIDO CENTRADO (Avatar y Nombre)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar con borde brillante
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black45,
                            blurRadius: 20,
                            spreadRadius: 5),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.surfaceBlack,
                      backgroundImage: _artist!.profileImageUrl != null
                          ? CachedNetworkImageProvider(
                              _artist!.profileImageUrl!)
                          : null,
                      child: _artist!.profileImageUrl == null
                          ? Text((_artist!.artistName ?? "?")[0],
                              style: const TextStyle(fontSize: 40))
                          : null,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 16),

                  // Nombre y Verificado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _artist!.artistName ?? _artist!.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (_artist!.verifiedArtist) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified,
                            color: AppTheme.primaryBlue, size: 24),
                      ],
                    ],
                  ).animate().fadeIn().slideY(begin: 0.3, end: 0),

                  // Label discográfica pequeña
                  if (_artist!.recordLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _artist!.recordLabel!,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistStatsAndBio(bool isFollowing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ESTADÍSTICAS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('${_artist!.followerIds.length}', 'Seguidores'),
              Container(
                  height: 30,
                  width: 1,
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 24)),
              _buildStatItem('${_songs.length}', 'Canciones'),
              Container(
                  height: 30,
                  width: 1,
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 24)),
              _buildStatItem('${_albums.length}', 'Álbumes'),
            ],
          ),

          const SizedBox(height: 24),

          // BOTÓN SEGUIR
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isFollowing ? Colors.transparent : Colors.white,
                foregroundColor: isFollowing ? Colors.white : Colors.black,
                elevation: isFollowing ? 0 : 5,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: isFollowing
                    ? const BorderSide(color: Colors.white30, width: 1.5)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                isFollowing ? 'SIGUIENDO' : 'SEGUIR',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ).animate().scale(delay: 200.ms),

          // BIO EXPANDIBLE (Simple por ahora)
          if (_artist!.artistBio != null) ...[
            const SizedBox(height: 24),
            Text(
              _artist!.artistBio!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), height: 1.5),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
      ],
    );
  }

  // --- TABS Y CONTENIDO ---

  Widget _buildTabBar() {
    return Container(
      color:
          const Color(0xFF121212), // Fondo sólido para cuando se pegue arriba
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryBlue,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'General'),
          Tab(text: 'Canciones'),
          Tab(text: 'Álbumes'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECCIÓN: CANCIONES POPULARES
          if (_songs.isNotEmpty) ...[
            const Text('Populares',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 16),
            ..._songs.take(5).map((song) => _buildSongTile(song)),
          ],

          const SizedBox(height: 32),

          // SECCIÓN: ÚLTIMOS LANZAMIENTOS
          if (_albums.isNotEmpty) ...[
            const Text('Lanzamientos',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _albums.take(5).length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) =>
                    _buildAlbumCard(_albums[index]),
              ),
            ),
          ],
          const SizedBox(height: 100), // Espacio para el miniplayer
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    if (_songs.isEmpty) {
      return const Center(
          child: Text("No hay canciones",
              style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _songs.length,
      itemBuilder: (context, index) => _buildSongTile(_songs[index]),
    );
  }

  Widget _buildAlbumsTab() {
    if (_albums.isEmpty) {
      return const Center(
          child:
              Text("No hay álbumes", style: TextStyle(color: Colors.white54)));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) =>
          _buildAlbumCard(_albums[index], isGrid: true),
    );
  }

  // --- COMPONENTES UI REUTILIZABLES ---

  Widget _buildSongTile(Song song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            imageUrl: song.coverImageUrl ?? '',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
                color: Colors.grey[800], child: const Icon(Icons.music_note)),
          ),
        ),
        title: Text(song.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
            maxLines: 1),
        subtitle: Text(song.durationFormatted,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
          onPressed: () =>
              Navigator.pushNamed(context, '/song', arguments: song.id),
        ),
        onTap: () => Navigator.pushNamed(context, '/song', arguments: song.id),
      ),
    );
  }

  Widget _buildAlbumCard(Album album, {bool isGrid = false}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/album', arguments: album.id),
      child: Container(
        width: isGrid ? null : 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: album.coverImageUrl ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[900]),
                  errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[900], child: const Icon(Icons.album)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            Text(
              album.releaseDate?.year.toString() ?? 'Album',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// Delegado para el TabBar pegajoso (Sticky)
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => 48.0;
  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _tabBar;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
