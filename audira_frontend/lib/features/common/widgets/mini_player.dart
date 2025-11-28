import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports de tu proyecto
import '../../../config/theme.dart';
import '../../../core/providers/audio_provider.dart';

class MiniPlayer extends StatelessWidget {
  // Puedes pasar un padding adicional si en alguna pantalla específica lo necesitas más arriba
  final double bottomPadding;

  const MiniPlayer(
      {super.key,
      this.bottomPadding = 12.0 // Margen estándar pequeño y elegante
      });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final song = audioProvider.currentSong;

        // Si no hay canción, no mostramos nada (ni ocupamos espacio)
        if (song == null || audioProvider.demoFinished) {
          return const SizedBox.shrink();
        }

        return Padding(
          // Usamos el bottomPadding aquí. Si hay un BottomNavBar flotante,
          // el Stack padre debería posicionar este widget encima, no el padding interno.
          padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/playback');
            },
            // Contenedor principal con animación de entrada
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                  12), // Bordes un poco menos redondos para encajar mejor con el menú
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 15, sigmaY: 15), // Blur más fuerte para legibilidad
                child: Container(
                  height: 64, // Altura compacta y elegante
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withValues(
                        alpha: 0.95), // Casi opaco para que destaque
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(
                            0, 4), // Sombra hacia abajo para separarlo
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Contenido Principal ---
                      Expanded(
                        child: Row(
                          children: [
                            // 1. Carátula
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Hero(
                                tag: 'miniplayer_art',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: song.coverImageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: song.coverImageUrl!,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                              color: AppTheme.surfaceBlack),
                                          errorWidget: (_, __, ___) =>
                                              Container(
                                                  color: AppTheme.surfaceBlack,
                                                  child: const Icon(
                                                      Icons.music_note,
                                                      size: 20)),
                                        )
                                      : Container(
                                          width: 48,
                                          height: 48,
                                          color: AppTheme.surfaceBlack,
                                          child: const Icon(Icons.music_note,
                                              color: Colors.white54),
                                        ),
                                ),
                              ),
                            ),

                            // 2. Info Texto
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Título
                                  Text(
                                    song.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // Artista
                                  Text(
                                    song.artistName,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // 3. Controles Mini
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    audioProvider.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    audioProvider.togglePlayPause();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded,
                                      color: Colors.white, size: 28),
                                  onPressed: () {
                                    audioProvider.next();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // --- Barra de Progreso Lineal (Al borde inferior) ---
                      if (audioProvider.totalDuration.inMilliseconds > 0)
                        LinearProgressIndicator(
                          value: audioProvider.progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBlue),
                          minHeight: 2,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
            .animate()
            .slideY(
                begin: 1.0, end: 0.0, duration: 300.ms, curve: Curves.easeOut)
            .fadeIn();
      },
    );
  }
}
