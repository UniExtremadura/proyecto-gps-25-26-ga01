import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../core/models/song.dart';

class SongCard extends StatelessWidget {
  final Song song;

  const SongCard({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/song', arguments: song.id);
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppTheme.cardBlack,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (Altura fija: 120)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: song.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: song.coverImageUrl!,
                      width: 160,
                      height: 120, // Altura fija
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 160,
                        height: 120,
                        color: AppTheme.surfaceBlack,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 160,
                        height: 120,
                        color: AppTheme.surfaceBlack,
                        child: const Icon(Icons.music_note, size: 48),
                      ),
                    )
                  : Container(
                      width: 160,
                      height: 120, // Altura fija
                      color: AppTheme.surfaceBlack,
                      child: const Icon(Icons.music_note, size: 48),
                    ),
            ),

            // Info (Ahora con padding vertical reducido)
            // No usamos Expanded aquí, dejamos que el tamaño se ajuste al contenido
            Padding(
              // MODIFICADO: Padding vertical reducido de 12 a 8
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min, // La columna ocupa solo lo necesario
                children: [
                  Text(
                    song.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // MODIFICADO: SizedBox reducido de 4 a 2
                  const SizedBox(height: 2),
                  Text(
                    song.durationFormatted,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  // MODIFICADO: SizedBox reducido de 4 a 2
                  const SizedBox(height: 2),
                  Text(
                    '\$${song.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
