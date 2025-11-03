// ignore_for_file: use_build_context_synchronously

import 'package:audira_frontend/config/theme.dart';
import 'package:audira_frontend/core/api/services/music_service.dart';
import 'package:audira_frontend/core/models/album.dart';
import 'package:audira_frontend/core/models/artist.dart';
import 'package:audira_frontend/core/models/rating.dart';
import 'package:audira_frontend/core/models/song.dart';
import 'package:audira_frontend/core/providers/audio_provider.dart';
import 'package:audira_frontend/core/providers/auth_provider.dart';
import 'package:audira_frontend/core/providers/cart_provider.dart';
import 'package:audira_frontend/core/providers/library_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/comment.dart';
import '../../../core/api/services/rating_service.dart';
import '../../../core/api/services/comment_service.dart';

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
  final CommentService _commentService = CommentService();

  Album? _album;
  Artist? _artist;
  List<Song> _songs = [];
  Map<String, dynamic>? _ratingStats;
  List<Rating> _ratings = [];
  List<Comment> _comments = [];

  bool _isLoading = true;
  bool _isLoadingRatings = true;
  bool _isLoadingComments = true;
  String? _error;

  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();
  int? _userRating;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAlbumDetails();
    _loadRatingsAndComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbumDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load album
      final albumResponse = await _musicService.getAlbumById(widget.albumId);
      if (albumResponse.success && albumResponse.data != null) {
        _album = albumResponse.data;

        // Load artist
        final artistResponse =
            await _musicService.getArtistById(_album!.artistId);
        if (artistResponse.success) {
          _artist = artistResponse.data;
        }

        // Load songs in album
        final songsResponse =
            await _musicService.getSongsByAlbum(widget.albumId);
        if (songsResponse.success && songsResponse.data != null) {
          _songs = songsResponse.data!;
          // Sort by track number if available
          _songs.sort(
              (a, b) => (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0));
        }
      } else {
        _error = albumResponse.error ?? 'Failed to load album';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRatingsAndComments() async {
    setState(() {
      _isLoadingRatings = true;
      _isLoadingComments = true;
    });

    try {
      // Load rating stats
      final statsResponse = await _ratingService.getEntityRatingStats(
        entityType: 'ALBUM',
        entityId: widget.albumId,
      );
      if (statsResponse.success) {
        _ratingStats = statsResponse.data;
      }

      // Load all ratings
      final ratingsResponse = await _ratingService.getEntityRatings(
        entityType: 'ALBUM',
        entityId: widget.albumId,
      );
      if (ratingsResponse.success && ratingsResponse.data != null) {
        _ratings = ratingsResponse.data!;
      }

      // Load user's rating if authenticated
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        final userRatingResponse = await _ratingService.getUserEntityRating(
          userId: authProvider.currentUser!.id,
          entityType: 'ALBUM',
          entityId: widget.albumId,
        );
        if (userRatingResponse.success && userRatingResponse.data != null) {
          // CORREGIDO: El campo se llama 'rating', no 'ratingValue'
          _userRating = userRatingResponse.data!.rating;
        }
      }

      setState(() => _isLoadingRatings = false);

      // Load comments
      final commentsResponse = await _commentService.getEntityComments(
        entityType: 'ALBUM',
        entityId: widget.albumId,
      );
      if (commentsResponse.success && commentsResponse.data != null) {
        _comments = commentsResponse.data!;
      }
    } catch (e) {
      debugPrint('Error loading ratings/comments: $e');
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _submitRating(int rating) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to rate this album')),
      );
      return;
    }

    try {
      final response = await _ratingService.createRating(
        userId: authProvider.currentUser!.id,
        entityType: 'ALBUM',
        entityId: widget.albumId,
        ratingValue:
            rating, // Este es el nombre del PARÁMETRO del servicio, está bien
      );

      if (response.success) {
        setState(() => _userRating = rating);
        _loadRatingsAndComments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Failed to submit rating')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _submitComment() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to comment')),
      );
      return;
    }

    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      final response = await _commentService.createComment(
        userId: authProvider.currentUser!.id,
        entityType: 'ALBUM',
        entityId: widget.albumId,
        content: content,
      );

      if (response.success) {
        _commentController.clear();
        _loadRatingsAndComments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Failed to post comment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _addToCart() async {
    if (_album == null) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login or register to add items to cart'),
        ),
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();
    try {
      // CORREGIDO: La llamada a 'addToCart' estaba mal formada.
      // Asumiendo que los parámetros son nombrados y 'quantity' es el nombre para '1'.
      await cartProvider.addToCart(
        userId: authProvider.currentUser!.id,
        itemType: 'ALBUM',
        itemId: _album!.id,
        price: _album!.price,
        quantity: 1,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album added to cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _album == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Album not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // CORREGIDO: El campo se llama 'name', no 'title'
        title: Text(_album!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final textToCopy = 'Check out "${_album!.name}" album on Audira!';
              Clipboard.setData(ClipboardData(text: textToCopy));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Album link copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAlbumHeader(),
                  _buildActionButtons(),
                  _buildTabs(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Hero(
            tag: 'album-${_album!.id}',
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _album!.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _album!.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.album, size: 48),
                      )
                    : const Icon(Icons.album, size: 48),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Album info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // CORREGIDO: El campo se llama 'name', no 'title'
                  _album!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_artist != null)
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/artist',
                        arguments: _artist!.id,
                      );
                    },
                    child: Text(
                      _artist!.artistName ?? _artist!.username,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (_album!.releaseDate != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _album!.releaseDate.toString().split(' ')[0],
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.music_note,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${_songs.length} songs',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money,
                        size: 16, color: AppTheme.textSecondary),
                    Text(
                      '\$${_album!.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                if (_ratingStats != null &&
                    _ratingStats!['averageRating'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index <
                                    (_ratingStats!['averageRating'] as num)
                                        .floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(_ratingStats!['averageRating'] as num).toStringAsFixed(1)} (${_ratingStats!['totalRatings']})',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildActionButtons() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isFavorite = libraryProvider.isAlbumFavorite(_album!.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (_album != null) {
                  audioProvider.playAlbum(_album!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playing album...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play Album'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addToCart,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Add to Cart'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              if (!authProvider.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please login to add favorites'),
                  ),
                );
                return;
              }
              try {
                await libraryProvider.toggleAlbumFavorite(
                  authProvider.currentUser!.id,
                  _album!,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFavorite
                        ? 'Removed from favorites'
                        : 'Added to favorites'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            color: isFavorite ? Colors.red : AppTheme.primaryBlue,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Ratings'),
            Tab(text: 'Comments'),
          ],
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSongsTab(),
              _buildRatingsTab(),
              _buildCommentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSongsTab() {
    if (_songs.isEmpty) {
      return const Center(child: Text('No songs in this album'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                song.trackNumber?.toString() ?? (index + 1).toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(song.name),
            subtitle: Text(song.durationFormatted),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () {
                    final audioProvider = context.read<AudioProvider>();
                    audioProvider.playSong(song, demo: true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Playing ${song.name} demo...'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/song',
                      arguments: song.id,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate this album',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => IconButton(
                icon: Icon(
                  index < (_userRating ?? 0) ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => _submitRating(index + 1),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingRatings)
            const Center(child: CircularProgressIndicator())
          else if (_ratings.isEmpty)
            const Center(child: Text('No ratings yet'))
          else
            ..._ratings.map((rating) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(rating.userId.toString()),
                    ),
                    title: Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          // CORREGIDO: El campo se llama 'rating', no 'ratingValue'
                          index < rating.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                    // CORREGIDO: Ahora 'comment' existe en el modelo Rating
                    subtitle:
                        rating.comment != null ? Text(rating.comment!) : null,
                    trailing: Text(
                      rating.createdAt.toString().split(' ')[0],
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        Expanded(
          child: _isLoadingComments
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                  ? const Center(child: Text('No comments yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(comment.userId.toString()[0]),
                            ),
                            title: Text('User ${comment.userId}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment.content),
                                const SizedBox(height: 4),
                                Text(
                                  comment.createdAt.toString().split('.')[0],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.thumb_up_outlined,
                                      size: 18),
                                  onPressed: () async {
                                    try {
                                      await _commentService
                                          .likeComment(comment.id);
                                      _loadRatingsAndComments();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Comment liked'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  },
                                ),
                                if (comment.likesCount > 0)
                                  Text('${comment.likesCount}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlack,
            border: Border(
              // CORREGIDO: 'withOpacity' está obsoleto, usando 'withValues'
              // según el patrón en tu propio código (línea 346).
              top: BorderSide(
                  color: AppTheme.textSecondary.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _submitComment,
                icon: const Icon(Icons.send),
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
