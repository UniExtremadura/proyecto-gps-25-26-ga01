import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MusicService _musicService = MusicService();

  List<Song> _songs = [];
  List<Album> _albums = [];
  bool _isLoading = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_songs.isEmpty && _albums.isEmpty) setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _musicService.getRecentPublishedSongs(),
        _musicService.getRecentPublishedAlbums(),
      ]);

      if (mounted) {
        final songsRes = results[0] as dynamic;
        final albumsRes = results[1] as dynamic;

        List<Song> tempSongs = [];
        List<Album> tempAlbums = [];

        if (songsRes.success && songsRes.data != null) {
          tempSongs = songsRes.data!;
        }
        if (albumsRes.success && albumsRes.data != null) {
          tempAlbums = albumsRes.data!;
        }

        setState(() {
          _songs = tempSongs;
          _albums = tempAlbums;
          _isLoading = false;
        });

        await _enrichContentData(tempSongs, tempAlbums);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enrichContentData(List<Song> songs, List<Album> albums) async {
    bool needsUpdate = false;
    final Map<int, String> artistCache = {};

    List<Song> enrichedSongs = List.from(songs);
    for (int i = 0; i < enrichedSongs.length; i++) {
      final s = enrichedSongs[i];
      if (_needsEnrichment(s.artistName)) {
        final realName = await _fetchArtistName(s.artistId, artistCache);
        if (realName != null) {
          enrichedSongs[i] = s.copyWith(artistName: realName);
          needsUpdate = true;
        }
      }
    }

    List<Album> enrichedAlbums = List.from(albums);
    for (int i = 0; i < enrichedAlbums.length; i++) {
      final a = enrichedAlbums[i];
      if (_needsEnrichment(a.artistName)) {
        final realName = await _fetchArtistName(a.artistId, artistCache);
        if (realName != null) {
          enrichedAlbums[i] = a.copyWith(artistName: realName);
          needsUpdate = true;
        }
      }
    }

    if (needsUpdate && mounted) {
      setState(() {
        _songs = enrichedSongs;
        _albums = enrichedAlbums;
      });
    }
  }

  bool _needsEnrichment(String name) {
    return name == 'Artista Desconocido' ||
        name.startsWith('Artist #') ||
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: AppTheme.backgroundBlack,
              surfaceTintColor: Colors.transparent,
              floating: true,
              pinned: true,
              snap: true,
              expandedHeight: 80,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.darkBlue.withValues(alpha: 0.3),
                        AppTheme.backgroundBlack
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('MERCADO MUSICAL',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 16)),
              centerTitle: true,
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryBlue,
                  labelColor: AppTheme.primaryBlue,
                  unselectedLabelColor: AppTheme.textGrey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'ÚLTIMAS CANCIONES'),
                    Tab(text: 'ÁLBUMES DESTACADOS')
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue))
            : TabBarView(
                controller: _tabController,
                children: [
                  _StoreContentTab(
                    type: 'songs',
                    items: _songs,
                    isGrid: false,
                    itemBuilder: (context, item) =>
                        _buildStoreSongTile(context, item as Song),
                  ),
                  _StoreContentTab(
                    type: 'albums',
                    items: _albums,
                    isGrid: true,
                    itemBuilder: (context, item) =>
                        _buildStoreAlbumCard(context, item as Album),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStoreSongTile(BuildContext context, Song song) {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, _) {
        final isPurchased = libraryProvider.isSongPurchased(song.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBlack,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isPurchased
                    ? AppTheme.successGreen.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(8),
                image: song.coverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(song.coverImageUrl!),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: song.coverImageUrl == null
                  ? const Icon(Icons.music_note, color: AppTheme.textGrey)
                  : null,
            ),
            title: Text(song.name,
                style: TextStyle(
                    color: isPurchased ? AppTheme.textGrey : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            subtitle: Text(song.artistName,
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
            trailing: isPurchased
                ? const Icon(Icons.check_circle, color: AppTheme.successGreen)
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: Text('\$${song.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
            onTap: () =>
                Navigator.pushNamed(context, '/song', arguments: song.id),
          ),
        );
      },
    );
  }

  Widget _buildStoreAlbumCard(BuildContext context, Album album) {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, _) {
        final isPurchased = libraryProvider.isAlbumPurchased(album.id);

        return GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, '/album', arguments: album.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBlack,
                        borderRadius: BorderRadius.circular(12),
                        image: album.coverImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(album.coverImageUrl!),
                                fit: BoxFit.cover,
                                colorFilter: isPurchased
                                    ? ColorFilter.mode(
                                        Colors.black.withValues(alpha: 0.5),
                                        BlendMode.darken)
                                    : null)
                            : null,
                      ),
                      child: album.coverImageUrl == null
                          ? const Center(
                              child: Icon(Icons.album,
                                  size: 40, color: AppTheme.textGrey))
                          : null,
                    ),
                    if (isPurchased)
                      Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: AppTheme.successGreen,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.check,
                                  size: 12, color: Colors.white))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(album.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: isPurchased ? AppTheme.textGrey : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(album.artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.textGrey, fontSize: 12))),
                  if (!isPurchased)
                    Text('\$${album.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

class _StoreContentTab extends StatefulWidget {
  final String type;
  final List<dynamic> items;
  final Widget Function(BuildContext, dynamic) itemBuilder;
  final bool isGrid;

  const _StoreContentTab(
      {required this.type,
      required this.items,
      required this.itemBuilder,
      required this.isGrid});

  @override
  State<_StoreContentTab> createState() => _StoreContentTabState();
}

class _StoreContentTabState extends State<_StoreContentTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.type == 'songs' ? Icons.music_note : Icons.album,
                size: 64, color: AppTheme.textGrey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
                "No hay ${widget.type == 'songs' ? 'canciones' : 'álbumes'} disponibles",
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 16)),
          ],
        ),
      );
    }
    if (widget.isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16),
        itemCount: widget.items.length,
        itemBuilder: (context, index) => widget
            .itemBuilder(context, widget.items[index])
            .animate(delay: (30 * index).ms)
            .fadeIn()
            .scale(),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.items.length,
      itemBuilder: (context, index) => widget
          .itemBuilder(context, widget.items[index])
          .animate(delay: (30 * index).ms)
          .fadeIn()
          .scale()
          .slideX(),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: AppTheme.backgroundBlack, child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
