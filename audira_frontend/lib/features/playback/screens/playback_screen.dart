import 'dart:ui'; // Necesario para el efecto Blur (ImageFilter)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback y Clipboard
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

// --- IMPORTS DE TU PROYECTO ---
import '../../../core/providers/audio_provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/models/song.dart';
import '../../../config/theme.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({super.key});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  @override
  void initState() {
    super.initState();
    // Verificamos si la demo terminó justo al entrar (caso borde)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<AudioProvider>();
        if (provider.demoFinished) {
          _showDemoFinishedDialog(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentContext = context;
    // Usamos Consumer para reconstruir la UI macro cuando cambia la canción o el estado Play/Pause
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final song = audioProvider.currentSong;

        // Listener reactivo para el fin de la demo dentro del árbol de widgets
        if (audioProvider.demoFinished) {
          // Usamos un microtask para evitar errores de construcción durante el renderizado
          Future.microtask(() {
            if (!currentContext.mounted) return;
            if (mounted && ModalRoute.of(currentContext)?.isCurrent == true) {
              _showDemoFinishedDialog(currentContext);
            }
          });
        }

        // Estado vacío: No hay canción seleccionada
        if (song == null) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundBlack,
            body: Center(
              child: Text("No hay música reproduciéndose",
                  style: TextStyle(color: Colors.white54)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          extendBodyBehindAppBar:
              true, // Permite que el fondo llegue hasta arriba
          appBar: _buildAppBar(context),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // -----------------------------------------------------------
              // 1. CAPA DE FONDO: PORTADA DIFUMINADA (GLASSMORPHISM)
              // -----------------------------------------------------------
              if (song.coverImageUrl != null)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: CachedNetworkImage(
                      imageUrl: song.coverImageUrl!,
                      fit: BoxFit.cover,
                      // Oscurecemos un poco la imagen base para que no sea tan brillante
                      color: Colors.black.withValues(alpha: 0.4),
                      colorBlendMode: BlendMode.darken,
                      errorWidget: (_, __, ___) =>
                          Container(color: AppTheme.backgroundBlack),
                    ),
                  ),
                )
              else
                Container(color: AppTheme.backgroundBlack),

              // -----------------------------------------------------------
              // 2. CAPA DE DEGRADADO (VIGNETTE)
              // -----------------------------------------------------------
              // Esto asegura que los textos blancos sean legibles siempre
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black
                          .withValues(alpha: 0.2), // Arriba un poco claro
                      Colors.black.withValues(alpha: 0.5), // Medio
                      const Color(0xFF0D0D0D), // Abajo negro sólido
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),

              // -----------------------------------------------------------
              // 3. CONTENIDO PRINCIPAL (SAFE AREA)
              // -----------------------------------------------------------
              SafeArea(
                child: Column(
                  children: [
                    // Espacio flexible superior
                    const Spacer(flex: 1),

                    // --- PORTADA GIRATORIA (VINILO) ---
                    _buildRotatingAlbumArt(song, audioProvider.isPlaying)
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.easeOutBack),

                    const Spacer(flex: 2),

                    // --- INFO DE LA CANCIÓN ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          if (audioProvider.isDemoMode)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color:
                                            Colors.amber.withValues(alpha: 0.4),
                                        blurRadius: 8)
                                  ]),
                              child: const Text(
                                "VISTA PREVIA (DEMO)",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 1),
                              ),
                            ).animate().fadeIn().slideY(begin: 1, end: 0),

                          // Título
                          Text(
                            song.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 8),

                          // Artista
                          Text(
                            song.artistName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ).animate().fadeIn(delay: 300.ms),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // --- BARRA DE PROGRESO (WIDGET OPTIMIZADO) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _ProgressSlider(audioProvider: audioProvider),
                    ),

                    const SizedBox(height: 10),

                    // --- CONTROLES DE REPRODUCCIÓN ---
                    _buildPlayerControls(audioProvider)
                        .animate()
                        .fadeIn(delay: 400.ms),

                    const Spacer(flex: 1),

                    // --- ACCIONES INFERIORES (Favoritos, Share, Playlist) ---
                    _buildBottomActions(context, song)
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.5, end: 0),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES DE DISEÑO
  // ===========================================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.white, size: 32),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Text(
            "REPRODUCIENDO DESDE",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "Tu Biblioteca", // Podría ser dinámico (Playlist, Album, etc.)
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.queue_music_rounded, color: Colors.white),
          onPressed: () => _showQueueBottomSheet(context),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onPressed: () => _showOptionsBottomSheet(context),
        ),
      ],
    );
  }

  Widget _buildRotatingAlbumArt(Song song, bool isPlaying) {
    // La imagen base
    Widget image = Container(
      width: 280, // Tamaño grande
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle, // Hacemos que sea un disco
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1), width: 2),
      ),
      child: ClipOval(
        child: song.coverImageUrl != null
            ? CachedNetworkImage(
                imageUrl: song.coverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[900]),
              )
            : Container(
                color: Colors.grey[900],
                child: const Icon(Icons.music_note,
                    size: 80, color: Colors.white24),
              ),
      ),
    );

    // Si está sonando, aplicamos rotación infinita
    if (isPlaying) {
      return image
          .animate(onPlay: (controller) => controller.repeat())
          .rotate(duration: 15.seconds, curve: Curves.linear);
    } else {
      // Si está pausado, devolvemos la imagen estática (o en su última posición si quisiéramos ser más complejos)
      return image;
    }
  }

  Widget _buildPlayerControls(AudioProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: provider.isShuffleEnabled
                ? AppTheme.primaryBlue
                : Colors.white38,
            size: 26,
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            provider.toggleShuffle();
          },
        ),

        // Previous
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded,
              color: Colors.blue, size: 42),
          onPressed: () {
            HapticFeedback.lightImpact();
            provider.previous();
          },
        ),

        // PLAY / PAUSE (Botón Hero)
        GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            provider.togglePlayPause();
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue, // Botón blanco clásico
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(
              provider.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.black, // Icono negro para contraste máximo
              size: 45,
            ),
          ).animate(target: provider.isPlaying ? 1 : 0).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 200.ms),
        ),

        // Next
        IconButton(
          icon:
              const Icon(Icons.skip_next_rounded, color: Colors.blue, size: 42),
          onPressed: () {
            HapticFeedback.lightImpact();
            provider.next();
          },
        ),

        // Repeat
        IconButton(
          icon: Icon(
            provider.repeatMode == RepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: provider.repeatMode != RepeatMode.off
                ? AppTheme.primaryBlue
                : Colors.white38,
            size: 26,
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            provider.toggleRepeat();
          },
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, Song song) {
    // Obtenemos Providers sin escuchar cambios (listen: false) para funciones,
    // y con Consumer o watch para UI reactiva si fuera necesario.
    // Aquí usamos Consumer para el icono de favorito específicamente.

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Share
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white70),
            onPressed: () => _shareSong(context, song),
          ),

          // Add to Playlist
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded, color: Colors.white70),
            onPressed: () => _showAddToPlaylistDialog(context, song),
          ),

          // Buy (Cart) - Solo si tiene precio > 0
          if (song.price > 0)
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: Colors.white70),
              onPressed: () => _addToCart(context, song),
            ),

          // Favorite (Reactive)
          Consumer<LibraryProvider>(
            builder: (context, library, child) {
              final isFav = library.isSongFavorite(song.id);
              return IconButton(
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? AppTheme.primaryBlue : Colors.white70,
                ),
                onPressed: () => _toggleFavorite(context, song),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LÓGICA DE NEGOCIO Y DIÁLOGOS
  // ===========================================================================

  void _shareSong(BuildContext context, Song song) {
    final text =
        '🎵 Escuchando "${song.name}" de ${song.artistName} en Audira!';
    Share.share(text);
  }

  Future<void> _toggleFavorite(BuildContext context, Song song) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para guardar favoritos')),
      );
      return;
    }

    HapticFeedback.selectionClick();
    await context
        .read<LibraryProvider>()
        .toggleSongFavorite(authProvider.currentUser!.id, song);
  }

  Future<void> _addToCart(BuildContext context, Song song) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para comprar')),
      );
      return;
    }

    try {
      final success = await context.read<CartProvider>().addToCart(
            userId: authProvider.currentUser!.id,
            itemType: 'SONG',
            itemId: song.id,
            price: song.price,
            quantity: 1,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(success ? 'Añadido al carrito' : 'Ya está en el carrito'),
          backgroundColor: success ? Colors.green : Colors.orange,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showQueueBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Para efecto flotante
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Consumer<AudioProvider>(
                builder: (context, audio, child) {
                  return Column(
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 20),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Cola de Reproducción",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () {
                                audio.clearQueue();
                                Navigator.pop(context);
                              },
                              child: const Text("Borrar",
                                  style: TextStyle(color: AppTheme.errorRed)),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: audio.queue.isEmpty
                            ? const Center(
                                child: Text("La cola está vacía",
                                    style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: audio.queue.length,
                                itemBuilder: (context, index) {
                                  final s = audio.queue[index];
                                  final isCurrent = index == audio.currentIndex;
                                  return ListTile(
                                    leading: isCurrent
                                        ? const Icon(Icons.graphic_eq,
                                            color: AppTheme.primaryBlue)
                                        : Text("${index + 1}",
                                            style: const TextStyle(
                                                color: Colors.grey)),
                                    title: Text(s.name,
                                        style: TextStyle(
                                            color: isCurrent
                                                ? AppTheme.primaryBlue
                                                : Colors.white,
                                            fontWeight: isCurrent
                                                ? FontWeight.bold
                                                : FontWeight.normal)),
                                    subtitle: Text(s.artistName,
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 18, color: Colors.grey),
                                      onPressed: () =>
                                          audio.removeFromQueue(index),
                                    ),
                                    onTap: () {
                                      audio.playSong(
                                          s); // Simplemente reproduce esa
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.album_outlined, color: Colors.white),
              title: const Text('Ver Álbum',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                final song = context.read<AudioProvider>().currentSong;
                if (song?.albumId != null) {
                  Navigator.pushNamed(context, '/album',
                      arguments: song!.albumId);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white),
              title: const Text('Ver Artista',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                final song = context.read<AudioProvider>().currentSong;
                if (song != null) {
                  Navigator.pushNamed(context, '/artist',
                      arguments: song.artistId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Song song) {
    final currentContext = context;
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Inicia sesión primero')));
      return;
    }

    final libraryProvider = context.read<LibraryProvider>();
    // Simplemente mostramos un diálogo básico, adaptado del código original
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        title: const Text('Añadir a Playlist',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: libraryProvider.playlists.isEmpty
              ? const Text('No tienes playlists. Crea una nueva.',
                  style: TextStyle(color: Colors.grey))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: libraryProvider.playlists.length,
                  itemBuilder: (ctx, index) {
                    final pl = libraryProvider.playlists[index];
                    return ListTile(
                      title: Text(pl.name,
                          style: const TextStyle(color: Colors.white)),
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await libraryProvider.addSongToPlaylist(
                              pl.id, song.id);
                          if (!currentContext.mounted) return;
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Añadido a ${pl.name}'),
                                backgroundColor: Colors.green));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/playlist/create');
            },
            child: const Text('Nueva Playlist'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
        ],
      ),
    );
  }

  void _showDemoFinishedDialog(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final currentSong = audioProvider.currentSong;

    // Determinar si el usuario está autenticado
    final isAuthenticated = authProvider.isAuthenticated;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252836),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.timer_off_rounded, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Text("Fin de la Demo", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          isAuthenticated
              ? "La vista previa de 10 segundos ha terminado.\n\nPara escuchar la canción completa, añádela al carrito y cómprala."
              : "La vista previa de 10 segundos ha terminado.\n\nRegístrate o inicia sesión para comprar la canción y escucharla completa.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra diálogo
              Navigator.pop(context); // Cierra pantalla de reproducción
            },
            child: const Text("Salir", style: TextStyle(color: Colors.grey)),
          ),
          if (isAuthenticated && currentSong != null && currentSong.price > 0)
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final success = await cartProvider.addToCart(
                    userId: authProvider.currentUser!.id,
                    itemType: 'SONG',
                    itemId: currentSong.id,
                    price: currentSong.price,
                    quantity: 1,
                  );
                  if (context.mounted) {
                    Navigator.pop(context); // Cerrar diálogo
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(success
                          ? 'Añadido al carrito'
                          : 'Ya está en el carrito'),
                      backgroundColor: success ? Colors.green : Colors.orange,
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue),
              icon: const Icon(Icons.shopping_cart),
              label: const Text("Añadir al Carrito"),
            ),
          if (!isAuthenticated)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pushNamed(context, '/register');
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue),
              child: const Text("Registrarse Gratis"),
            ),
        ],
      ),
    );
  }
}

class _ProgressSlider extends StatefulWidget {
  final AudioProvider audioProvider;

  const _ProgressSlider({required this.audioProvider});

  @override
  State<_ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<_ProgressSlider> {
  // Variable local para gestionar el arrastre sin saltos
  double? _dragValue;
  bool _isDragging = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = widget.audioProvider.totalDuration;
    final currentPos = widget.audioProvider.currentPosition;

    // Calculamos el progreso (0.0 a 1.0) asegurando que no dividimos por cero
    double progress = 0.0;
    if (totalDuration.inMilliseconds > 0) {
      progress = currentPos.inMilliseconds / totalDuration.inMilliseconds;
    }

    // LÓGICA CLAVE: Si el usuario está arrastrando (_dragValue != null),
    // usamos ese valor para dibujar el slider. Si no, usamos el del Provider.
    // Esto evita que el slider "tiemble" o salte hacia atrás mientras arrastras.
    final displayValue = _isDragging && _dragValue != null
        ? _dragValue!
        : progress.clamp(0.0, 1.0);

    // Calculamos el tiempo a mostrar en texto (dinámico mientras arrastras)
    final displayTime = _isDragging && _dragValue != null
        ? Duration(
            milliseconds: (_dragValue! * totalDuration.inMilliseconds).round())
        : currentPos;

    return Column(
      children: [
        // Usamos SliderTheme para hacerlo más fino y elegante
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2, // Fino
            thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6, pressedElevation: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.blue,
            inactiveTrackColor: Colors.blue.withValues(alpha: 0.2),
            thumbColor: Colors.blue,
            overlayColor: Colors.blue.withValues(alpha: 0.2),
            trackShape: const RectangularSliderTrackShape(),
          ),
          child: Slider(
            value: displayValue,
            min: 0.0,
            max: 1.0,
            // Solo permitimos interaction si la duración es válida
            onChanged: (totalDuration.inMilliseconds > 0)
                ? (value) {
                    // Actualizamos SOLO el estado local mientras arrastra
                    setState(() {
                      _dragValue = value.clamp(0.0, 1.0);
                    });
                  }
                : null,
            onChangeStart: (_) {
              // Marcar que estamos arrastrando
              setState(() {
                _isDragging = true;
              });
            },
            onChangeEnd: (value) async {
              try {
                // Al soltar, enviamos el comando de seek
                final clampedValue = value.clamp(0.0, 1.0);
                final newPos = Duration(
                    milliseconds:
                        (clampedValue * totalDuration.inMilliseconds).round());

                // Realizar el seek
                await widget.audioProvider.seek(newPos);
              } catch (e) {
                debugPrint('Error en seek desde slider: $e');
              } finally {
                // Limpiamos el valor de arrastre para volver a escuchar al provider
                if (mounted) {
                  setState(() {
                    _isDragging = false;
                    _dragValue = null;
                  });
                }
              }
            },
          ),
        ),

        // Tiempos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(displayTime),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              Text(
                _formatDuration(totalDuration),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
