// ignore_for_file: use_build_context_synchronously

import 'package:audira_frontend/config/theme.dart';
import 'package:audira_frontend/core/api/services/music_service.dart';
import 'package:audira_frontend/core/models/album.dart';
import 'package:audira_frontend/core/models/artist.dart';
import 'package:audira_frontend/core/models/collaborator.dart';
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
  final CommentService _commentService = CommentService();

  Song? _song;
  Album? _album;
  Artist? _artist;
  List<Collaborator> _collaborators = [];
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
    _loadSongDetails();
    _loadRatingsAndComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
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
          if (albumResponse.success) {
            _album = albumResponse.data;
          }
        }

        final artistResponse =
            await _musicService.getArtistById(_song!.artistId);
        if (artistResponse.success) {
          _artist = artistResponse.data;
        }

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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRatingsAndComments() async {
    setState(() {
      _isLoadingRatings = true;
      _isLoadingComments = true;
    });

    try {
      final statsResponse = await _ratingService.getEntityRatingStats(
        entityType: 'SONG',
        entityId: widget.songId,
      );
      if (statsResponse.success) {
        _ratingStats = statsResponse.data;
      }

      final ratingsResponse = await _ratingService.getEntityRatings(
        entityType: 'SONG',
        entityId: widget.songId,
      );
      if (ratingsResponse.success && ratingsResponse.data != null) {
        _ratings = ratingsResponse.data!;
      }

      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        final userRatingResponse = await _ratingService.getUserEntityRating(
          userId: authProvider.currentUser!.id,
          entityType: 'SONG',
          entityId: widget.songId,
        );
        if (userRatingResponse.success && userRatingResponse.data != null) {
          _userRating = userRatingResponse.data!.rating;
        }
      }

      setState(() => _isLoadingRatings = false);

      final commentsResponse = await _commentService.getEntityComments(
        entityType: 'SONG',
        entityId: widget.songId,
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
        const SnackBar(content: Text('Please login to rate this song')),
      );
      return;
    }

    try {
      final response = await _ratingService.createRating(
        userId: authProvider.currentUser!.id,
        entityType: 'SONG',
        entityId: widget.songId,
        ratingValue: rating,
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
        entityType: 'SONG',
        entityId: widget.songId,
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
    if (_song == null) return;

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
      await cartProvider.addToCart(
        userId: authProvider.currentUser!.id,
        itemType: 'SONG',
        itemId: _song!.id,
        price: _song!.price,
        quantity: 1,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song added to cart')),
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

    if (_error != null || _song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Song not found'),
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
        title: Text(_song!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final textToCopy = 'Check out "${_song!.name}" on Audira!';
              Clipboard.setData(ClipboardData(text: textToCopy));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Song link copied to clipboard')),
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
                  _buildSongHeader(),
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

  Widget _buildSongHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'song-${_song!.id}',
            child: Container(
              width: 120,
              height: 120,
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
                child: _song!.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _song!.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.music_note, size: 48),
                      )
                    : const Icon(Icons.music_note, size: 48),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _song!.name,
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
                if (_album != null)
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/album',
                        arguments: _album!.id,
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.album, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _album!.name,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _song!.durationFormatted,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money,
                        size: 16, color: AppTheme.textSecondary),
                    Text(
                      '\$${_song!.price.toStringAsFixed(2)}',
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
                          '${(_ratingStats!['averageRating'] as num).toStringAsFixed(1)} (${_ratingStats!['totalRatings']} ratings)',
                          style: TextStyle(color: AppTheme.textSecondary),
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
    final isFavorite = libraryProvider.isSongFavorite(_song!.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (_song != null) {
                  audioProvider.playSong(_song!, demo: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playing 10-second demo...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play Demo'),
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
                await libraryProvider.toggleSongFavorite(
                  authProvider.currentUser!.id,
                  _song!,
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
            Tab(text: 'Details'),
            Tab(text: 'Ratings'),
            Tab(text: 'Comments'),
          ],
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(),
              _buildRatingsTab(),
              _buildCommentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_song!.description != null && _song!.description!.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_song!.description!),
            const SizedBox(height: 16),
          ],
          if (_collaborators.isNotEmpty) ...[
            const Text(
              'Collaborators',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._collaborators.map((collab) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text('Artist ID: ${collab.artistId}'),
                  subtitle: Text(collab.role),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/artist',
                      arguments: collab.artistId,
                    );
                  },
                )),
            const SizedBox(height: 16),
          ],
          if (_song!.lyrics != null && _song!.lyrics!.isNotEmpty) ...[
            const Text(
              'Lyrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _song!.lyrics!,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate this song',
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
                          index < rating.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
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
