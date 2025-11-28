import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

// Mantenemos tus imports
import '../../../core/providers/download_provider.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/downloaded_song.dart';
import '../../../core/models/song.dart';
import '../../../config/theme.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- LÓGICA ---

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  // --- AQUÍ ESTÁ EL CAMBIO SOLICITADO ---
  Future<void> _playSong(DownloadedSong downloadedSong) async {
    final audioProvider = context.read<AudioProvider>();
    final authProvider = context.read<AuthProvider>();

    // Verificamos si la canción pulsada es la que está cargada actualmente en el reproductor
    final isCurrentSong =
        audioProvider.currentSong?.id == downloadedSong.songId;

    if (isCurrentSong) {
      if (audioProvider.isPlaying) {
        // 1. Si ya está sonando -> La pausamos
        await audioProvider.pause();
      } else {
        // 2. Si estaba pausada -> La reiniciamos desde el principio (00:00)
        await audioProvider.seek(Duration.zero);
        await audioProvider.resume();
      }
    } else {
      // 3. Si es una canción diferente -> La reproducimos normalmente
      final song = Song(
        id: downloadedSong.songId,
        artistId: 0,
        artistName: downloadedSong.artistName,
        name: downloadedSong.songName,
        duration: downloadedSong.duration,
        price: 0,
        coverImageUrl: downloadedSong.coverImageUrl,
        audioUrl: downloadedSong.localFilePath,
      );
      // IMPORTANTE: Marcar como descargada para que no se reproduzca en modo demo
      await audioProvider.playSong(
        song,
        isDownloaded: true,
        isUserAuthenticated: authProvider.isAuthenticated,
        userId: authProvider.currentUser?.id,
      );
    }
  }

  // --- DIÁLOGOS PERSONALIZADOS ---

  Future<void> _confirmDelete(
      {required String title,
      required String content,
      required VoidCallback onConfirm}) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.2),
              foregroundColor: Colors.red,
              elevation: 0,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllDownloads() async {
    _confirmDelete(
      title: 'Vaciar biblioteca',
      content:
          '¿Estás seguro de que quieres eliminar todas las canciones descargadas? Esta acción es irreversible.',
      onConfirm: () async {
        final success =
            await context.read<DownloadProvider>().clearAllDownloads();
        if (mounted) {
          _showSnackBar(success, 'Biblioteca vaciada', 'Error al vaciar');
        }
      },
    );
  }

  Future<void> _deleteSingleDownload(DownloadedSong song) async {
    _confirmDelete(
      title: 'Eliminar descarga',
      content: '¿Eliminar "${song.songName}" de tus descargas?',
      onConfirm: () async {
        final success =
            await context.read<DownloadProvider>().deleteDownload(song.songId);
        if (mounted) {
          _showSnackBar(success, 'Canción eliminada', 'Error al eliminar');
        }
      },
    );
  }

  void _showSnackBar(bool success, String successMsg, String errorMsg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error,
                color: Colors.white),
            const SizedBox(width: 12),
            Text(success ? successMsg : errorMsg),
          ],
        ),
        backgroundColor: success ? AppTheme.successGreen : AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- UI PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final songs = _searchQuery.isEmpty
        ? downloadProvider.getDownloadedSongsSorted()
        : downloadProvider.searchDownloadedSongs(_searchQuery);

    final stats = downloadProvider.getDownloadStats();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. APP BAR
          _buildSliverAppBar(songs.isNotEmpty),

          // 2. STATS
          if (songs.isNotEmpty && !_isSearching)
            SliverToBoxAdapter(
              child: _buildStatsHeader(stats),
            ),

          // 3. LISTA
          songs.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      return _buildSongTile(song)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: (50 * index).ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                    childCount: songs.length,
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSliverAppBar(bool hasDownloads) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF121212),
      floating: true,
      pinned: true,
      elevation: 0,
      expandedHeight: 80,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Buscar canción o artista...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ).animate().fadeIn()
          : const Text(
              "Mis Descargas",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
      actions: [
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(
            _isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: Colors.white,
          ),
        ),
        if (hasDownloads && !_isSearching)
          IconButton(
            onPressed: _clearAllDownloads,
            icon: const Icon(Icons.delete_sweep_outlined,
                color: Colors.redAccent),
            tooltip: "Eliminar todo",
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsHeader(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F222B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.music_note_rounded,
            value: "${stats['totalDownloads']}",
            label: "Canciones",
            color: AppTheme.primaryBlue,
          ),
          Container(height: 30, width: 1, color: Colors.white10),
          _buildStatItem(
            icon: Icons.sd_storage_rounded,
            value: "${stats['totalSizeMB']} MB",
            label: "Espacio",
            color: AppTheme.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSongTile(DownloadedSong song) {
    final audioProvider = context.watch<AudioProvider>();
    final isPlaying =
        audioProvider.currentSong?.id == song.songId && audioProvider.isPlaying;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isPlaying
            ? AppTheme.primaryBlue.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isPlaying
            ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3))
            : Border(
                bottom:
                    BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _playSong(song),
          onLongPress: () => _deleteSingleDownload(song),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // PORTADA
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Hero(
                      tag: 'cover_${song.songId}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: song.coverImageUrl ?? '',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[900]),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[900],
                            child: const Icon(Icons.music_note,
                                color: Colors.white24),
                          ),
                        ),
                      ),
                    ),
                    if (isPlaying)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.graphic_eq,
                            color: AppTheme.primaryBlue),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 1000.ms),
                  ],
                ),

                const SizedBox(width: 16),

                // INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.songName,
                        style: TextStyle(
                          color:
                              isPlaying ? AppTheme.primaryBlue : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artistName,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildMetaTag(
                              song.fileSizeFormatted, Icons.data_usage),
                          const SizedBox(width: 8),
                          _buildMetaTag(
                              song.format.toUpperCase(), Icons.audio_file),
                          const SizedBox(width: 8),
                          _buildMetaTag(
                            timeago.format(song.downloadedAt, locale: 'es'),
                            Icons.access_time,
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // MENÚ
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.white38, size: 20),
                  onPressed: () => _deleteSingleDownload(song),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaTag(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.white30),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(color: Colors.white30, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isEmpty
                  ? Icons.cloud_download_outlined
                  : Icons.search_off_rounded,
              size: 60,
              color: Colors.white12,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty
                ? 'Tu biblioteca está vacía'
                : 'Sin resultados',
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Las canciones descargadas aparecerán aquí\npara escucharlas sin conexión.'
                : 'Intenta buscar con otro término.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
