import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../core/providers/audio_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final song = audioProvider.currentSong;

        // Don't show mini player if no song is playing
        if (song == null || audioProvider.demoFinished) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/playback');
          },
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlack,
              border: Border(
                top: BorderSide(
                  color: AppTheme.textGrey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Album Art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: song.coverImageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.backgroundBlack,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.backgroundBlack,
                              child: const Icon(Icons.music_note, size: 30),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: AppTheme.backgroundBlack,
                            child: const Icon(Icons.music_note, size: 30),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Song Info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (audioProvider.isDemoMode)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'DEMO',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (audioProvider.isDemoMode)
                              const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                song.artistName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textGrey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 28,
                        color: Colors.white,
                        onPressed: () {
                          audioProvider.previous();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          audioProvider.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        iconSize: 32,
                        color: AppTheme.primaryBlue,
                        onPressed: () {
                          audioProvider.togglePlayPause();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 28,
                        color: Colors.white,
                        onPressed: () {
                          audioProvider.next();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
