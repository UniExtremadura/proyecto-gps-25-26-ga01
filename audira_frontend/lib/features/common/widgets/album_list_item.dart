import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports de tu proyecto
import 'package:audira_frontend/core/providers/auth_provider.dart';
import 'package:audira_frontend/core/providers/cart_provider.dart';
import 'package:audira_frontend/core/providers/library_provider.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../core/models/album.dart';

class AlbumListItem extends StatelessWidget {
  final Album album;
  final void Function()? onTap;

  const AlbumListItem({
    super.key,
    required this.album,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ??
              () {
                Navigator.pushNamed(context, '/album', arguments: album.id);
              },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 1. Carátula del Álbum
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: album.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: album.coverImageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceBlack,
                            child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceBlack,
                            child:
                                const Icon(Icons.album, color: Colors.white24),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: AppTheme.surfaceBlack,
                          child: const Icon(Icons.album, color: Colors.white24),
                        ),
                ),

                const SizedBox(width: 16),

                // 2. Información del Álbum
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (album.discountPercentage > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primaryBlue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${album.discountPercentage}%',
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '\$${album.discountedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Botón de Acción (Comprado / Añadir al carrito)
                Consumer2<LibraryProvider, AuthProvider>(
                  builder: (context, libraryProvider, authProvider, child) {
                    final isPurchased =
                        libraryProvider.isAlbumPurchased(album.id);

                    if (isPurchased) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  AppTheme.successGreen.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle_outline,
                                size: 14, color: AppTheme.successGreen),
                            SizedBox(width: 4),
                            Text(
                              'Adquirido',
                              style: TextStyle(
                                color: AppTheme.successGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return IconButton(
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      color: AppTheme.primaryBlue,
                      tooltip: 'Añadir al carrito',
                      onPressed: () async {
                        if (!authProvider.isAuthenticated) {
                          _showSnackBar(context, 'Inicia sesión para comprar',
                              isError: true);
                          return;
                        }

                        final cartProvider = context.read<CartProvider>();
                        final success = await cartProvider.addToCart(
                          userId: authProvider.currentUser!.id,
                          itemType: AppConstants.itemTypeAlbum,
                          itemId: album.id,
                          price: album.discountedPrice,
                          quantity: 1,
                        );

                        if (context.mounted) {
                          _showSnackBar(
                            context,
                            success
                                ? '${album.name} añadido al carrito'
                                : 'Ya está en el carrito',
                            isError: !success,
                            isWarning: !success,
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppTheme.errorRed
            : isWarning
                ? Colors.orange
                : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
