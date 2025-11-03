// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/models/artist.dart';
import '../../../core/api/services/discovery_service.dart';
import '../../../config/theme.dart';
import '../../common/widgets/song_list_item.dart';
import '../../common/widgets/album_list_item.dart';

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

  List<Song> _songs = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];

  bool _isLoading = false;
  bool _hasSearched = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTrendingContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingContent() async {
    setState(() => _isLoading = true);

    try {
      final songsResponse = await _discoveryService.getTrendingSongs(limit: 10);
      final albumsResponse =
          await _discoveryService.getTrendingAlbums(limit: 10);

      if (songsResponse.success && songsResponse.data != null) {
        _songs = songsResponse.data!;
      }

      if (albumsResponse.success && albumsResponse.data != null) {
        _albums = albumsResponse.data!;
      }
    } catch (e) {
      debugPrint('Error loading trending content: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _hasSearched = false;
        _songs = [];
        _albums = [];
        _artists = [];
      });
      _loadTrendingContent();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // Search songs
      final songsResponse = await _discoveryService.searchSongs(query);
      if (songsResponse.success && songsResponse.data != null) {
        _songs = songsResponse.data!;
      }

      // Search albums
      final albumsResponse = await _discoveryService.searchAlbums(query);
      if (albumsResponse.success && albumsResponse.data != null) {
        _albums = albumsResponse.data!;
      }

      // Artist search functionality
      _artists = [];
    } catch (e) {
      debugPrint('Search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search songs, albums, artists...',
            hintStyle: TextStyle(color: AppTheme.textGrey),
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
          onChanged: (value) {
            setState(() {});
            // Debounce search
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchController.text == value) {
                _performSearch(value);
              }
            });
          },
          onSubmitted: _performSearch,
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
    if (!_hasSearched) {
      return _buildTrendingSection();
    }

    if (_songs.isEmpty && _albums.isEmpty && _artists.isEmpty) {
      return _buildEmptyState();
    }

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
            'Trending Now',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),
          if (_songs.isNotEmpty) ...[
            const Text(
              'Trending Songs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._songs.map((song) => SongListItem(
                  song: song,
                  onTap: () =>
                      Navigator.pushNamed(context, '/song', arguments: song.id),
                )),
          ],
          if (_albums.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Trending Albums',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._albums.map((album) => AlbumListItem(
                  album: album,
                  onTap: () => Navigator.pushNamed(context, '/album',
                      arguments: album.id),
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
          const Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.textGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
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
            const Text(
              'Songs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._songs.take(5).map((song) => SongListItem(
                  song: song,
                  onTap: () =>
                      Navigator.pushNamed(context, '/song', arguments: song.id),
                )),
            if (_songs.length > 5)
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text('View all songs'),
              ),
            const SizedBox(height: 16),
          ],
          if (_albums.isNotEmpty) ...[
            const Text(
              'Albums',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._albums.take(5).map((album) => AlbumListItem(
                  album: album,
                  onTap: () => Navigator.pushNamed(context, '/album',
                      arguments: album.id),
                )),
            if (_albums.length > 5)
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: const Text('View all albums'),
              ),
            const SizedBox(height: 16),
          ],
          if (_artists.isNotEmpty) ...[
            const Text(
              'Artists',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._artists.take(5).map((artist) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(artist.artistName ?? artist.username),
                  onTap: () => Navigator.pushNamed(context, '/artist',
                      arguments: artist.id),
                )),
            if (_artists.length > 5)
              TextButton(
                onPressed: () => _tabController.animateTo(3),
                child: const Text('View all artists'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return SongListItem(
          song: song,
          onTap: () =>
              Navigator.pushNamed(context, '/song', arguments: song.id),
        );
      },
    );
  }

  Widget _buildAlbumsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return AlbumListItem(
          album: album,
          onTap: () =>
              Navigator.pushNamed(context, '/album', arguments: album.id),
        );
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
          onTap: () =>
              Navigator.pushNamed(context, '/artist', arguments: artist.id),
        );
      },
    );
  }
}
