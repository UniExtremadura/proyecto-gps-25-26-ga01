import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/auth_provider.dart';
import 'edit_song_screen.dart';
import 'edit_album_screen.dart';

class StudioCatalogScreen extends StatefulWidget {
  const StudioCatalogScreen({super.key});

  @override
  State<StudioCatalogScreen> createState() => _StudioCatalogScreenState();
}

class _StudioCatalogScreenState extends State<StudioCatalogScreen>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  late TabController _tabController;

  List<Song> _songs = [];
  List<Album> _albums = [];
  bool _isLoading = false;
  String? _error;

  String _filterStatus =
      'all'; // all, published, hidden, pending, approved, rejected
  String _sortBy = 'recent'; // recent, name, plays

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artistId = authProvider.currentUser!.id;

      final songsResponse = await _musicService.getSongsByArtist(artistId);
      if (songsResponse.success && songsResponse.data != null) {
        _songs = songsResponse.data!;
      }

      final albumsResponse = await _musicService.getAlbumsByArtist(artistId);
      if (albumsResponse.success && albumsResponse.data != null) {
        _albums = albumsResponse.data!;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Lógica de Negocio (Intacta) ---

  Future<void> _editSong(Song song) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EditSongScreen(song: song)),
    );
    if (result == true) _loadCatalog();
  }

  Future<void> _editAlbum(Album album) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EditAlbumScreen(album: album)),
    );
    if (result == true) _loadCatalog();
  }

  Future<void> _toggleSongPublished(Song song) async {
    if (!song.published && song.moderationStatus != 'APPROVED') {
      _showModerationAlert(song.moderationStatus!);
      return;
    }
    try {
      final response =
          await _musicService.publishSong(song.id, !song.published);
      if (response.success) {
        _showSnack(song.published ? 'Ocultado' : 'Publicado');
        _loadCatalog();
      } else {
        _showSnack('Error: ${response.error}', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _toggleAlbumPublished(Album album) async {
    if (!album.published && album.moderationStatus != 'APPROVED') {
      _showModerationAlert(album.moderationStatus!);
      return;
    }
    try {
      final response =
          await _musicService.publishAlbum(album.id, !album.published);
      if (response.success) {
        _showSnack(album.published ? 'Ocultado' : 'Publicado');
        _loadCatalog();
      } else {
        _showSnack('Error: ${response.error}', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _deleteSong(int songId) async {
    final confirmed = await _showDeleteDialog('Eliminar Canción');
    if (confirmed == true) {
      try {
        final response = await _musicService.deleteSong(songId);
        if (response.success) {
          _showSnack('Eliminado correctamente');
          _loadCatalog();
        }
      } catch (e) {
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  Future<void> _deleteAlbum(int albumId) async {
    final confirmed = await _showDeleteDialog('Eliminar Álbum');
    if (confirmed == true) {
      try {
        final response = await _musicService.deleteAlbum(albumId);
        if (response.success) {
          _showSnack('Eliminado correctamente');
          _loadCatalog();
        }
      } catch (e) {
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        elevation: 0,
        title: const Text('MI CATÁLOGO',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
                color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textGrey,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'CANCIONES'),
            Tab(text: 'ÁLBUMES'),
          ],
        ),
        actions: [
          _buildFilterMenu(),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppTheme.errorRed)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_filteredSongs, isSong: true),
                    _buildList(_filteredAlbums, isSong: false),
                  ],
                ),
    );
  }

  Widget _buildList(List<dynamic> items, {required bool isSong}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSong ? Icons.music_note_rounded : Icons.album_rounded,
                size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            Text(
              'No hay ${isSong ? 'canciones' : 'álbumes'} para mostrar',
              style: const TextStyle(color: AppTheme.textGrey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCatalogItem(item, isSong: isSong)
            .animate(delay: (50 * index).ms)
            .fadeIn()
            .slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildCatalogItem(dynamic item, {required bool isSong}) {
    final bool isPublished = item.published;
    final String status = item.moderationStatus;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => isSong ? _editSong(item) : _editAlbum(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Cover
                _buildCover(item.coverImageUrl, isPublished, isSong),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (!isPublished) ...[
                            _buildStatusTag('OCULTO', Colors.grey),
                            const SizedBox(width: 6),
                          ],
                          _buildModerationTag(status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isSong
                            ? '${item.plays} reproducciones • \$${item.price.toStringAsFixed(2)}'
                            : '${item.songCount ?? 0} canciones • \$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 12),
                      ),
                      if (item.rejectionReason != null &&
                          item.rejectionReason!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Rechazo: ${item.rejectionReason}',
                            style: const TextStyle(
                                color: AppTheme.errorRed, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.textGrey),
                  color: AppTheme.surfaceBlack,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    _buildPopupItem('edit', 'Editar', Icons.edit),
                    _buildPopupItem(
                        'toggle',
                        isPublished ? 'Ocultar' : 'Publicar',
                        isPublished ? Icons.visibility_off : Icons.visibility),
                    const PopupMenuDivider(),
                    _buildPopupItem('delete', 'Eliminar', Icons.delete,
                        color: AppTheme.errorRed),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      isSong ? _editSong(item) : _editAlbum(item);
                    }
                    if (value == 'toggle') {
                      isSong
                          ? _toggleSongPublished(item)
                          : _toggleAlbumPublished(item);
                    }
                    if (value == 'delete') {
                      isSong ? _deleteSong(item.id) : _deleteAlbum(item.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(String? url, bool isPublished, bool isSong) {
    if (!isPublished) {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
            color: Colors.white10, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.visibility_off, color: Colors.white38),
      );
    }
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url, width: 70, height: 70, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
          color: AppTheme.surfaceBlack, borderRadius: BorderRadius.circular(8)),
      child: Icon(isSong ? Icons.music_note : Icons.album,
          color: AppTheme.primaryBlue),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildModerationTag(String status) {
    Color color;
    String text;
    switch (status) {
      case 'APPROVED':
        color = AppTheme.successGreen;
        text = 'APROBADO';
        break;
      case 'REJECTED':
        color = AppTheme.errorRed;
        text = 'RECHAZADO';
        break;
      default:
        color = AppTheme.warningOrange;
        text = 'EN REVISIÓN';
    }
    return _buildStatusTag(text, color);
  }

  PopupMenuItem<String> _buildPopupItem(
      String value, String text, IconData icon,
      {Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color ?? Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFilterMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
      color: AppTheme.surfaceBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        setState(() {
          if (['all', 'published', 'hidden', 'pending', 'approved', 'rejected']
              .contains(value)) {
            _filterStatus = value;
          } else {
            _sortBy = value;
          }
        });
      },
      itemBuilder: (context) => [
        _buildFilterHeader('ESTADO'),
        _buildFilterOption('all', 'Todas'),
        _buildFilterOption('published', 'Publicadas'),
        _buildFilterOption('hidden', 'Ocultas'),
        _buildFilterOption('pending', 'En Revisión',
            icon: Icons.hourglass_empty, color: Colors.orange),
        _buildFilterOption('rejected', 'Rechazadas',
            icon: Icons.cancel, color: Colors.red),
        const PopupMenuDivider(),
        _buildFilterHeader('ORDENAR'),
        _buildSortOption('recent', 'Recientes'),
        _buildSortOption('plays', 'Reproducciones'),
      ],
    );
  }

  PopupMenuItem<String> _buildFilterHeader(String text) {
    return PopupMenuItem(
      enabled: false,
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey)),
    );
  }

  PopupMenuItem<String> _buildFilterOption(String value, String text,
      {IconData? icon, Color? color}) {
    final isSelected = _filterStatus == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textGrey,
              size: 20),
          const SizedBox(width: 12),
          Text(text,
              style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textGrey)),
          if (icon != null) ...[
            const Spacer(),
            Icon(icon, size: 16, color: color),
          ]
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortOption(String value, String text) {
    final isSelected = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textGrey,
              size: 20),
          const SizedBox(width: 12),
          Text(text,
              style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textGrey)),
        ],
      ),
    );
  }

  // --- Helpers Funcionales ---

  List<Song> get _filteredSongs {
    var filtered = _songs.where((song) {
      if (_filterStatus == 'published') return song.published;
      if (_filterStatus == 'hidden') return !song.published;
      if (_filterStatus == 'pending') return song.moderationStatus == 'PENDING';
      if (_filterStatus == 'approved') {
        return song.moderationStatus == 'APPROVED';
      }
      if (_filterStatus == 'rejected') {
        return song.moderationStatus == 'REJECTED';
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'plays':
        filtered.sort((a, b) => b.plays.compareTo(a.plays));
        break;
      default:
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
    }
    return filtered;
  }

  List<Album> get _filteredAlbums {
    var filtered = _albums.where((album) {
      if (_filterStatus == 'published') return album.published;
      if (_filterStatus == 'hidden') return !album.published;
      if (_filterStatus == 'pending') {
        return album.moderationStatus == 'PENDING';
      }
      if (_filterStatus == 'approved') {
        return album.moderationStatus == 'APPROVED';
      }
      if (_filterStatus == 'rejected') {
        return album.moderationStatus == 'REJECTED';
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
    }
    return filtered;
  }

  void _showModerationAlert(String status) {
    String msg = status == 'PENDING'
        ? 'Contenido en revisión. Espera aprobación.'
        : 'Contenido rechazado. Edítalo para reenviar.';
    _showSnack(msg, isError: true);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<bool?> _showDeleteDialog(String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBlack,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro? Esta acción es irreversible.',
            style: TextStyle(color: AppTheme.textGrey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: AppTheme.errorRed))),
        ],
      ),
    );
  }
}
