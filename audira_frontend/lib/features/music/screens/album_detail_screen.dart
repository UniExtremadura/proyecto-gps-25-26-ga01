import 'dart:ui'; // Para ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports de tu proyecto
import 'package:audira_frontend/config/theme.dart';
import 'package:audira_frontend/core/api/services/music_service.dart';
import 'package:audira_frontend/core/models/album.dart';
import 'package:audira_frontend/core/models/artist.dart';
import 'package:audira_frontend/core/models/rating.dart';
import 'package:audira_frontend/core/models/rating_stats.dart';
import 'package:audira_frontend/core/models/song.dart';
import 'package:audira_frontend/core/providers/audio_provider.dart';
import 'package:audira_frontend/core/providers/auth_provider.dart';
import 'package:audira_frontend/core/providers/cart_provider.dart';
import 'package:audira_frontend/core/providers/library_provider.dart';
import 'package:audira_frontend/features/common/widgets/app_bottom_navigation_bar.dart';
import 'package:audira_frontend/features/common/widgets/mini_player.dart';
import '../../../core/api/services/rating_service.dart';
import '../../../core/api/services/library_service.dart';
import '../../../features/rating/widgets/rating_dialog.dart';
import '../../../features/rating/widgets/rating_list.dart';

class AlbumDetailScreen extends StatefulWidget {
  final int albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  final RatingService _ratingService = RatingService();
  final LibraryService _libraryService = LibraryService();

  Album? _album;
  Artist? _artist;
  List<Song> _songs = [];
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
    _loadAlbumDetails();
    _loadRatingsAndComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- LOGIC (Carga de datos intacta) ---

  Future<void> _loadAlbumDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final albumResponse = await _musicService.getAlbumById(widget.albumId);
      if (albumResponse.success && albumResponse.data != null) {
        _album = albumResponse.data;

        final artistResponse =
            await _musicService.getArtistById(_album!.artistId);
        if (artistResponse.success) {
          _artist = artistResponse.data;
        }

        final songsResponse =
            await _musicService.getSongsByAlbum(widget.albumId);
        if (songsResponse.success && songsResponse.data != null) {
          _songs = songsResponse.data!;
          _songs.sort(
              (a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0));
        }
      } else {
        _error = albumResponse.error ?? 'Failed to load album';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRatingsAndComments() async {
    final currentContext = context;
    setState(() => _isLoadingRatings = true);

    try {
      final statsResponse = await _ratingService.getEntityRatingStats(
        entityType: 'ALBUM',
        entityId: widget.albumId,
      );
      if (statsResponse.success) {
        _ratingStats = statsResponse.data;
      }

      final ratingsResponse = await _ratingService.getEntityRatingsWithComments(
        entityType: 'ALBUM',
        entityId: widget.albumId,
      );
      if (ratingsResponse.success && ratingsResponse.data != null) {
        _ratingsWithComments = ratingsResponse.data!;
      }

      if (!currentContext.mounted) return;
      final authProvider = currentContext.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        final myRatingResponse = await _ratingService.getMyEntityRating(
          entityType: 'ALBUM',
          entityId: widget.albumId,
        );
        if (myRatingResponse.success) {
          _myRating = myRatingResponse.data;
        } else {
          _myRating = null;
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
    if (_album == null) return;
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    final cartProvider = context.read<CartProvider>();
    try {
      final success = await cartProvider.addToCart(
        userId: authProvider.currentUser!.id,
        itemType: 'ALBUM',
        itemId: _album!.id,
        price: _album!.price,
        quantity: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? '${_album!.name} añadido al carrito'
              : '${_album!.name} ya está en el carrito'),
          backgroundColor: success ? AppTheme.successGreen : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
      }
    }
  }

  Future<void> _showRatingDialog() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    if (_myRating == null) {
      final purchaseResponse = await _libraryService.checkIfPurchased(
        authProvider.currentUser!.id,
        'ALBUM',
        widget.albumId,
      );
      if (!purchaseResponse.success || !(purchaseResponse.data ?? false)) {
        if (mounted) _showPurchaseRequiredDialog();
        return;
      }
    }

    if (!mounted) return;
    final result = await showRatingDialog(
      context,
      entityType: 'ALBUM',
      entityId: widget.albumId,
      existingRating: _myRating,
      entityName: _album?.name,
    );

    if (result == true) {
      _loadRatingsAndComments();
      _loadMyRating();
    }
  }

  Future<void> _loadMyRating() async {
    if (!context.read<AuthProvider>().isAuthenticated) return;
    try {
      final response = await _ratingService.getMyEntityRating(
          entityType: 'ALBUM', entityId: widget.albumId);
      if (mounted) setState(() => _myRating = response.data);
    } catch (_) {}
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        title:
            const Text('Inicie Sesión', style: TextStyle(color: Colors.white)),
        content: const Text('Necesitas una cuenta para realizar esta acción.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        title: const Text('Compra requerida',
            style: TextStyle(color: Colors.white)),
        content: const Text('Debes comprar el álbum para valorarlo.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addToCart();
            },
            child: const Text('Comprar'),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    if (_error != null || _album == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
            child: Text(_error ?? 'Álbum no encontrado',
                style: const TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // FONDO CON BLUR DE LA PORTADA
          Positioned.fill(
            child: Container(
              color: const Color(0xFF121212),
              child: Opacity(
                opacity: 0.3,
                child: CachedNetworkImage(
                  imageUrl: _album!.coverImageUrl ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.black),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),

          // CONTENIDO PRINCIPAL
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildAlbumInfo()),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(_buildTabBar()),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildSongsList(),
                _buildRatingsView(),
              ],
            ),
          ),

          // MINI PLAYER
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(selectedIndex: null),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF121212).withValues(alpha: 0.8),
      expandedHeight: 300.0,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () {
            Clipboard.setData(
                ClipboardData(text: 'Escucha ${_album!.name} en Audira!'));
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Link copiado')));
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 20),
            child: Hero(
              tag: 'album-${_album!.id}',
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _album!.coverImageUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[900]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumInfo() {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final isFavorite = libraryProvider.isAlbumFavorite(_album!.id);
    final isPurchased = libraryProvider.isAlbumPurchased(_album!.id);
    final isInCart = cartProvider.isItemInCart('ALBUM', _album!.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        children: [
          Text(
            _album!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          if (_artist != null)
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/artist',
                  arguments: _artist!.id),
              child: Text(
                _artist!.artistName ?? _artist!.username,
                style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ),

          const SizedBox(height: 16),

          // METADATA ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMetaPill('${_album!.releaseDate?.year ?? "Unknown"}'),
              const SizedBox(width: 8),
              _buildMetaPill('${_songs.length} Tracks'),
              const SizedBox(width: 8),
              if (_ratingStats != null)
                _buildMetaPill(
                    '★ ${_ratingStats!.averageRating.toStringAsFixed(1)}'),
            ],
          ),

          const SizedBox(height: 24),

          // ACTIONS ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PLAY / BUY / IN CART BUTTON
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isPurchased
                      ? () => _playAlbum()
                      : isInCart
                          ? () => Navigator.pushNamed(context, '/cart')
                          : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPurchased
                        ? AppTheme.primaryBlue
                        : isInCart
                            ? AppTheme.warningOrange
                            : Colors.white,
                    foregroundColor:
                        isPurchased || isInCart ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: Icon(
                    isPurchased
                        ? Icons.play_arrow_rounded
                        : isInCart
                            ? Icons.shopping_cart
                            : Icons.add_shopping_cart,
                    size: 20,
                  ),
                  label: Text(
                    isPurchased
                        ? 'REPRODUCIR'
                        : isInCart
                            ? 'EN CARRITO'
                            : 'COMPRAR \$${_album!.price}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // FAVORITE BUTTON
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon:
                      Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                  color: isFavorite ? AppTheme.errorRed : Colors.white,
                  onPressed: () => _toggleFavorite(isFavorite),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMetaPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(
          0xFF121212), // Debe coincidir con fondo para efecto sticky
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryBlue,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(text: 'Canciones'),
          Tab(text: 'Valoraciones'),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    return ListView.builder(
      physics:
          const NeverScrollableScrollPhysics(), // Scroll controlado por NestedScrollView
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return _buildSongTile(song, index);
      },
    );
  }

  Widget _buildSongTile(Song song, int index) {
    final authProvider = context.read<AuthProvider>();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 40,
        alignment: Alignment.center,
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ),
      title: Text(
        song.name,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _artist?.artistName ?? 'Unknown Artist',
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(song.durationFormatted,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Colors.white70),
            onPressed: () {
              _playAlbum(startIndex: index, authProvider: authProvider);
            },
          ),
        ],
      ),
      onTap: () => _playAlbum(startIndex: index, authProvider: authProvider),
    );
  }

  Widget _buildRatingsView() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          if (_isLoadingRatings)
            const Center(child: CircularProgressIndicator())
          else if (_ratingsWithComments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("Aún no hay valoraciones.",
                  style: TextStyle(color: Colors.white54)),
            )
          else
            RatingList(
              ratings: _ratingsWithComments,
              currentUserId: context.read<AuthProvider>().currentUser?.id,
              onRatingChanged: _loadRatingsAndComments,
            ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _showRatingDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: Icon(_myRating != null ? Icons.edit : Icons.star_outline),
            label: Text(
                _myRating != null ? 'Editar mi reseña' : 'Escribir reseña'),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---

  void _playAlbum({int startIndex = 0, AuthProvider? authProvider}) {
    if (_songs.isEmpty) return;

    authProvider ??= context.read<AuthProvider>();
    final audioProvider = context.read<AudioProvider>();

    audioProvider.playQueue(
      _songs,
      startIndex: startIndex,
      isUserAuthenticated: authProvider.isAuthenticated,
      userId: authProvider.currentUser?.id,
    );
    Navigator.pushNamed(context, '/playback');

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reproduciendo Demo (10s)')),
      );
    }
  }

  Future<void> _toggleFavorite(bool isFavorite) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    try {
      await context.read<LibraryProvider>().toggleAlbumFavorite(
            authProvider.currentUser!.id,
            _album!,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// Clase delegada para el TabBar pegajoso (Sticky Header)
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => 48.0; // Altura estándar del TabBar
  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _tabBar;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
