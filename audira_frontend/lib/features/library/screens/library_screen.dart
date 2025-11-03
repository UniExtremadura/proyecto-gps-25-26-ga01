import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/playlist_service.dart';
import '../../../core/models/playlist.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PlaylistService _playlistService = PlaylistService();

  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPlaylists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    setState(() => _isLoading = true);

    final response =
        await _playlistService.getUserPlaylists(authProvider.currentUser!.id);
    if (response.success && response.data != null) {
      _playlists = response.data!;
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.surfaceBlack,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppTheme.primaryBlue,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textGrey,
            tabs: const [
              Tab(text: 'Canciones'),
              Tab(text: 'Álbumes'),
              Tab(text: 'Playlists'),
              Tab(text: 'Favoritos'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Songs
              _buildEmptyState('Canciones', Icons.music_note),

              // Albums
              _buildEmptyState('Álbumes', Icons.album),

              // Playlists
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _playlists.isEmpty
                      ? _buildEmptyState('Playlists', Icons.playlist_play)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = _playlists[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.playlist_play),
                                ),
                                title: Text(playlist.name),
                                subtitle: Text(
                                  '${playlist.songCount} canciones',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textGrey,
                                      ),
                                ),
                                trailing: Icon(
                                  playlist.isPublic ? Icons.public : Icons.lock,
                                  color: AppTheme.textGrey,
                                ),
                                onTap: () {
                                  // Navigate to playlist detail page
                                },
                              ),
                            );
                          },
                        ),

              // Favorites
              _buildEmptyState('Favoritos', Icons.favorite),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.textGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay $title',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tus $title aparecerán aquí',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textGrey,
                ),
          ),
        ],
      ),
    );
  }
}
