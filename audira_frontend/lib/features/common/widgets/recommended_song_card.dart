import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/recommended_song.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/library_provider.dart';

/// Widget card for displaying a recommended song
/// GA01-117: Módulo básico de recomendaciones (placeholder)
class RecommendedSongCard extends StatelessWidget {
  final RecommendedSong song;

  const RecommendedSongCard({super.key, required this.song});

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
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: song.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: song.imageUrl!,
                          width: 160,
                          height: 120,
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
                          height: 120,
                          color: AppTheme.surfaceBlack,
                          child: const Icon(Icons.music_note, size: 48),
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Consumer<LibraryProvider>(
                    builder: (context, libraryProvider, child) {
                      final isPurchased =
                          libraryProvider.isSongPurchased(song.id);

                      if (isPurchased) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Comprado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final currentContext = context;
                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);
                            final cartProvider = Provider.of<CartProvider>(
                                context,
                                listen: false);

                            if (!authProvider.isAuthenticated) {
                              if (!currentContext.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Inicia sesión para añadir al carrito'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            if (song.price == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Esta canción no está disponible para compra'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            final success = await cartProvider.addToCart(
                              userId: authProvider.currentUser!.id,
                              itemType: 'SONG',
                              itemId: song.id,
                              price: song.price!,
                              quantity: 1,
                            );

                            if (!currentContext.mounted) return;

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${song.title} añadido al carrito'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${song.title} ya está en el carrito'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artistName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGrey,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Show reason for recommendation (if available)
                  if (song.reason != null)
                    Text(
                      song.reason!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (song.reason != null) const SizedBox(height: 2),
                  if (song.price != null)
                    Text(
                      '\$${song.price!.toStringAsFixed(2)}',
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
