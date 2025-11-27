import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/api/services/rating_service.dart';
import '../../../core/api/services/library_service.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/models/artist.dart';
import '../../../core/models/collaborator.dart';
import '../../../core/models/rating.dart';
import '../../../core/models/rating_stats.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../features/common/widgets/mini_player.dart';
import '../../../features/rating/widgets/rating_dialog.dart';
import '../../../features/rating/widgets/rating_list.dart';
import '../../../features/downloads/widgets/download_button.dart';

class SongDetailScreen extends StatefulWidget {
  final int songId;

  const SongDetailScreen({super.key, required this.songId});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  final RatingService _ratingService = RatingService();
  final LibraryService _libraryService = LibraryService();

  Song? _song;
  Album? _album;
  Artist? _artist;
  List<Collaborator> _collaborators = [];
  RatingStats? _ratingStats;
  List<Rating> _ratingsWithComments = [];
  Rating? _myRating;

  bool _isLoading = true;
  bool _isLoadingRatings = true;
  String? _error;

  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSongDetails();
      _loadRatingsAndComments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSongDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final songResponse = await _musicService.getSongById(widget.songId);
      if (songResponse.success && songResponse.data != null) {
        _song = songResponse.data;

        if (_song!.albumId != null) {
          final albumResponse =
              await _musicService.getAlbumById(_song!.albumId!);
          if (albumResponse.success) _album = albumResponse.data;
        }

        final artistResponse =
            await _musicService.getArtistById(_song!.artistId);
        if (artistResponse.success) _artist = artistResponse.data;

        final collabResponse =
            await _musicService.getCollaboratorsBySongId(widget.songId);
        if (collabResponse.success && collabResponse.data != null) {
          _collaborators = collabResponse.data!;
        }
      } else {
        _error = songResponse.error ?? 'Failed to load song';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRatingsAndComments() async {
    if (!mounted) return;
    setState(() => _isLoadingRatings = true);

    try {
      final statsResponse = await _ratingService.getEntityRatingStats(
          entityType: 'SONG', entityId: widget.songId);
      if (statsResponse.success) _ratingStats = statsResponse.data;

      final ratingsResponse = await _ratingService.getEntityRatingsWithComments(
          entityType: 'SONG', entityId: widget.songId);
      if (ratingsResponse.success && ratingsResponse.data != null) {
        _ratingsWithComments = ratingsResponse.data!;
      }

      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.isAuthenticated) {
          final myRatingResponse = await _ratingService.getMyEntityRating(
              entityType: 'SONG', entityId: widget.songId);
          if (myRatingResponse.success) _myRating = myRatingResponse.data;
        }
      }
    } catch (e) {
      debugPrint('Error loading ratings: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRatings = false);
    }
  }

  // --- ACTIONS ---

  Future<void> _addToCart() async {
    if (_song == null) return;
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    final cartProvider = context.read<CartProvider>();
    try {
      final success = await cartProvider.addToCart(
        userId: authProvider.currentUser!.id,
        itemType: 'SONG',
        itemId: _song!.id,
        price: _song!.price,
        quantity: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? '${_song!.name} añadido al carrito'
              : 'Ya está en el carrito'),
          backgroundColor: success ? AppTheme.successGreen : Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBlack,
        title:
            const Text('Inicia Sesión', style: TextStyle(color: Colors.white)),
        content: const Text('Necesitas una cuenta para realizar esta acción.',
            style: TextStyle(color: AppTheme.textGrey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingDialog() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    if (_myRating == null) {
      final purchaseRes = await _libraryService.checkIfPurchased(
          authProvider.currentUser!.id, 'SONG', widget.songId);

      if (!purchaseRes.success || !(purchaseRes.data ?? false)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Debes comprar la canción para valorarla'),
            backgroundColor: Colors.orange,
          ));
        }
        return;
      }
    }

    if (!mounted) return;
    final result = await showRatingDialog(
      context,
      entityType: 'SONG',
      entityId: widget.songId,
      existingRating: _myRating,
      entityName: _song?.name,
    );

    if (result == true) {
      _loadRatingsAndComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    if (_error != null || _song == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
            child: Text(_error ?? 'Song not found',
                style: const TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. HEADER INMERSIVO (COVER ART)
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppTheme.backgroundBlack,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo borroso
                  if (_song!.coverImageUrl != null)
                    Image.network(
                      _song!.coverImageUrl!,
                      fit: BoxFit.cover,
                    ).animate().fadeIn(duration: 800.ms),

                  // Blur Overlay
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child:
                        Container(color: Colors.black.withValues(alpha: 0.5)),
                  ),

                  // Gradiente inferior
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.backgroundBlack
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Portada Central
                  Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 60), // Ajuste por SafeArea
                      child: Hero(
                        tag: 'song-${_song!.id}',
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10))
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _song!.coverImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: _song!.coverImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        Container(color: AppTheme.cardBlack),
                                  )
                                : Container(
                                    color: AppTheme.cardBlack,
                                    child: const Icon(Icons.music_note,
                                        size: 80, color: AppTheme.textGrey),
                                  ),
                          ),
                        )
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.easeOutBack),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: 'Check out "${_song!.name}" on Audira!'));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copiado')));
                },
              ),
            ],
          ),

          // 2. INFO PRINCIPAL Y ACCIONES
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    _song!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),

                  const SizedBox(height: 4),

                  // Artista
                  GestureDetector(
                    onTap: _artist != null
                        ? () => Navigator.pushNamed(context, '/artist',
                            arguments: _artist!.id)
                        : null,
                    child: Text(
                      _artist?.artistName ??
                          _artist?.username ??
                          _song!.artistName,
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 16),

                  // Metadata Row (Album, Año, Duración)
                  Row(
                    children: [
                      if (_album != null) ...[
                        const Icon(Icons.album_outlined,
                            size: 16, color: AppTheme.textGrey),
                        const SizedBox(width: 4),
                        Text(_album!.name,
                            style: const TextStyle(
                                color: AppTheme.textGrey, fontSize: 13)),
                        const SizedBox(width: 12),
                      ],
                      const Icon(Icons.timer_outlined,
                          size: 16, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(_song!.durationFormatted,
                          style: const TextStyle(
                              color: AppTheme.textGrey, fontSize: 13)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Botones de Acción (Play & Buy)
                  _buildActionButtons(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // 3. TABS (Detalles / Reseñas)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryBlue,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textGrey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'DETALLES'),
                  Tab(text: 'RESEÑAS'),
                ],
              ),
            ),
          ),

          // 4. CONTENIDO DE TABS
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildRatingsTab(),
              ],
            ),
          ),
        ],
      ),
      // MiniPlayer siempre visible abajo
      bottomNavigationBar: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildActionButtons() {
    final audioProvider = Provider.of<AudioProvider>(context);
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isPurchased = libraryProvider.isSongPurchased(_song!.id);
    final isFavorite = libraryProvider.isSongFavorite(_song!.id);

    return Row(
      children: [
        // Play Button (Grande)
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              audioProvider.playSong(_song!,
                  isUserAuthenticated: authProvider.isAuthenticated,
                  userId: authProvider.currentUser?.id);
              Navigator.pushNamed(context, '/playback');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: const Text("PLAY",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 14)),
          ),
        ),
        const SizedBox(width: 16),

        // Buy/Owned Button
        Expanded(
          flex: 2,
          child: isPurchased
              ? ElevatedButton.icon(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardBlack,
                    disabledBackgroundColor: AppTheme.cardBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color:
                                AppTheme.successGreen.withValues(alpha: 0.5))),
                  ),
                  label: const Text("COMPRADO",
                      style: TextStyle(
                          color: AppTheme.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                )
              : ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("\$${_song!.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ),
        ),
        const SizedBox(width: 16),

        // Favorite Button
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBlack,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isFavorite ? AppTheme.errorRed : Colors.transparent),
          ),
          child: IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppTheme.errorRed : Colors.white),
            onPressed: () async {
              if (authProvider.isAuthenticated) {
                await libraryProvider.toggleSongFavorite(
                    authProvider.currentUser!.id, _song!);
              } else {
                _showLoginDialog();
              }
            },
          ),
        ),

        // Download Button
        if (isPurchased) ...[
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
                color: AppTheme.cardBlack,
                borderRadius: BorderRadius.circular(12)),
            child: DownloadButton(song: _song!),
          ),
        ]
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción
          if (_song!.description != null && _song!.description!.isNotEmpty) ...[
            const Text("DESCRIPCIÓN",
                style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(_song!.description!,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.5)),
            const SizedBox(height: 32),
          ],

          // Colaboradores
          if (_collaborators.isNotEmpty) ...[
            const Text("CRÉDITOS",
                style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _collaborators
                  .map((c) => Chip(
                        avatar: const CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person,
                                size: 14, color: Colors.white)),
                        label: Text(
                            '${c.role}: Artist #${c.artistId}'), // Idealmente buscar nombre
                        backgroundColor: AppTheme.cardBlack,
                        labelStyle:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
          ],

          // Letras
          if (_song!.lyrics != null && _song!.lyrics!.isNotEmpty) ...[
            const Text("LETRA",
                style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Text(
                _song!.lyrics!,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.8,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingsTab() {
    return _isLoadingRatings
        ? const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue))
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Resumen de Ratings
              if (_ratingStats != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppTheme.cardBlack, AppTheme.surfaceBlack]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _ratingStats!.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              children: List.generate(
                                  5,
                                  (i) => Icon(
                                      i < _ratingStats!.averageRating.round()
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 20))),
                          const SizedBox(height: 4),
                          Text('${_ratingStats!.totalRatings} opiniones',
                              style: const TextStyle(color: AppTheme.textGrey)),
                        ],
                      )
                    ],
                  ),
                ),

              // Botón de valorar
              OutlinedButton.icon(
                onPressed: _showRatingDialog,
                icon: Icon(_myRating != null ? Icons.edit : Icons.star_border),
                label: Text(
                    _myRating != null ? "EDITAR MI RESEÑA" : "ESCRIBIR RESEÑA"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Lista
              RatingList(
                ratings: _ratingsWithComments,
                currentUserId: context.read<AuthProvider>().currentUser?.id,
                onRatingChanged: _loadRatingsAndComments,
              ),

              const SizedBox(height: 80), // Espacio final
            ],
          );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _StickyTabBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: AppTheme.backgroundBlack, child: _tabBar);
  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}
