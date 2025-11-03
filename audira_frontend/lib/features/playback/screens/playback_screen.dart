// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/providers/audio_provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/models/song.dart';
import '../../../config/theme.dart';

class PlaybackScreen extends StatelessWidget {
  const PlaybackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () {
              _showQueueBottomSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsBottomSheet(context);
            },
          ),
        ],
      ),
      body: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          if (audioProvider.demoFinished) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                Navigator.of(context).pop();
              }
            });
            return const Center(child: CircularProgressIndicator());
          }
          final song = audioProvider.currentSong;

          if (song == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.music_off,
                    size: 64,
                    color: AppTheme.textGrey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No song playing',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Browse Music'),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: _buildAlbumArt(song, audioProvider)
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildSongInfo(context, song)
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 32),
                  _buildProgressBar(audioProvider)
                      .animate()
                      .fadeIn(delay: 400.ms),
                  const SizedBox(height: 32),
                  _buildPlaybackControls(audioProvider)
                      .animate()
                      .fadeIn(delay: 600.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 24),
                  _buildSecondaryControls(context, audioProvider, song)
                      .animate()
                      .fadeIn(delay: 800.ms),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumArt(Song song, AudioProvider audioProvider) {
    Widget rotatingDisc = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceBlack,
      ),
      child: ClipOval(
        child: song.coverImageUrl != null
            ? CachedNetworkImage(
                imageUrl: song.coverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.music_note,
                  size: 64,
                  color: AppTheme.textGrey,
                ),
              )
            : const Icon(
                Icons.music_note,
                size: 64,
                color: AppTheme.textGrey,
              ),
      ),
    );

    if (audioProvider.isPlaying) {
      rotatingDisc = rotatingDisc
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .rotate(
            duration: 15.seconds,
            curve: Curves.linear,
          );
    }

    return Hero(
      tag: 'song-${song.id}',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            rotatingDisc,
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.backgroundBlack,
                  border: Border.all(
                    color: AppTheme.textGrey.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
            if (audioProvider.isDemoMode)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, Song song) {
    return Column(
      children: [
        Text(
          song.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/artist', arguments: song.artistId);
          },
          child: Text(
            song.artistName,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (song.albumId != null) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/album', arguments: song.albumId);
            },
            child: const Text(
              'View Album',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(AudioProvider audioProvider) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppTheme.primaryBlue,
            inactiveTrackColor: AppTheme.textGrey.withValues(alpha: 0.3),
            thumbColor: AppTheme.primaryBlue,
            overlayColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
          ),
          child: Slider(
            value: audioProvider.progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final position = audioProvider.totalDuration * value;
              audioProvider.seek(position);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(audioProvider.currentPosition),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGrey,
                ),
              ),
              Text(
                _formatDuration(audioProvider.totalDuration),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(AudioProvider audioProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            audioProvider.isShuffleEnabled
                ? Icons.shuffle_on_rounded
                : Icons.shuffle,
            color: audioProvider.isShuffleEnabled
                ? AppTheme.primaryBlue
                : AppTheme.textGrey,
          ),
          iconSize: 28,
          onPressed: audioProvider.toggleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 40,
          onPressed: audioProvider.previous,
        ),
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
            ),
          ),
          child: audioProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : IconButton(
                  icon: Icon(
                    audioProvider.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  iconSize: 40,
                  color: Colors.white,
                  onPressed: audioProvider.togglePlayPause,
                ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 40,
          onPressed: audioProvider.next,
        ),
        IconButton(
          icon: Icon(
            audioProvider.repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: audioProvider.repeatMode != RepeatMode.off
                ? AppTheme.primaryBlue
                : AppTheme.textGrey,
          ),
          iconSize: 28,
          onPressed: audioProvider.toggleRepeat,
        ),
      ],
    );
  }

  Widget _buildSecondaryControls(
      BuildContext context, AudioProvider audioProvider, Song song) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isFavorite = libraryProvider.isSongFavorite(song.id);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          iconSize: 28,
          color: isFavorite ? Colors.red : AppTheme.textGrey,
          onPressed: () async {
            if (!authProvider.isAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please login to add favorites')),
              );
              return;
            }
            try {
              await libraryProvider.toggleSongFavorite(
                authProvider.currentUser!.id,
                song,
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
        ),
        IconButton(
          icon: const Icon(Icons.playlist_add),
          iconSize: 28,
          color: AppTheme.textGrey,
          onPressed: () {
            _showAddToPlaylistDialog(context, song);
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          iconSize: 28,
          color: AppTheme.textGrey,
          onPressed: () {
            _shareSong(context, song);
          },
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          iconSize: 28,
          color: AppTheme.textGrey,
          onPressed: () {
            Navigator.pushNamed(context, '/song', arguments: song.id);
          },
        ),
      ],
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Song song) {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add to playlist')),
      );
      return;
    }

    final libraryProvider = context.read<LibraryProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Create New Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/playlist/create');
                },
              ),
              const Divider(),
              if (libraryProvider.playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No playlists yet'),
                )
              else
                ...libraryProvider.playlists.map((playlist) => ListTile(
                      leading: const Icon(Icons.playlist_play),
                      title: Text(playlist.name),
                      onTap: () async {
                        try {
                          await libraryProvider.addSongToPlaylist(
                            playlist.id,
                            song.id,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to ${playlist.name}'),
                            ),
                          );
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                    )),
            ],
          ),
        ),
      ),
    );
  }

  void _shareSong(BuildContext context, Song song) async {
    try {
      final shareText = '🎵 Escucha "${song.name}" en Audira!\n\n'
          'Precio: \$${song.price.toStringAsFixed(2)}\n'
          'Duración: ${song.durationFormatted}\n\n'
          '¡Disponible ahora!';

      await Share.share(
        shareText,
        subject: 'Mira esta canción en Audira',
      );
    } catch (e) {
      final textToCopy = 'Escucha "${song.name}" en Audira!';
      Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace copiado al portapapeles')),
      );
    }
  }

  void _showQueueBottomSheet(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceBlack,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Queue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    audioProvider.clearQueue();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: audioProvider.queue.isEmpty
                  ? const Center(child: Text('Queue is empty'))
                  : ListView.builder(
                      itemCount: audioProvider.queue.length,
                      itemBuilder: (context, index) {
                        final song = audioProvider.queue[index];
                        final isCurrent = index == audioProvider.currentIndex;

                        return ListTile(
                          leading: isCurrent
                              ? const Icon(Icons.play_circle_filled,
                                  color: AppTheme.primaryBlue)
                              : Text('${index + 1}'),
                          title: Text(
                            song.name,
                            style: TextStyle(
                              color: isCurrent
                                  ? AppTheme.primaryBlue
                                  : Colors.white,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(song.artistName),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              audioProvider.removeFromQueue(index);
                            },
                          ),
                          onTap: () {
                            audioProvider.playSong(song);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();
    final currentSong = audioProvider.currentSong;
    if (currentSong == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceBlack,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Add to Cart'),
            onTap: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              if (!authProvider.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please login to add items to cart'),
                  ),
                );
                return;
              }
              final cartProvider = context.read<CartProvider>();
              try {
                await cartProvider.addToCart(
                  userId: authProvider.currentUser!.id,
                  itemType: 'SONG',
                  itemId: currentSong.id,
                  price: currentSong.price,
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
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistDialog(context, currentSong);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Add to Favorites'),
            onTap: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              if (!authProvider.isAuthenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please login to add favorites')),
                );
                return;
              }
              final libraryProvider = context.read<LibraryProvider>();
              try {
                await libraryProvider.toggleSongFavorite(
                  authProvider.currentUser!.id,
                  currentSong,
                );
                final isFavorite =
                    libraryProvider.isSongFavorite(currentSong.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFavorite
                        ? 'Added to favorites'
                        : 'Removed from favorites'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              _shareSong(context, currentSong);
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
