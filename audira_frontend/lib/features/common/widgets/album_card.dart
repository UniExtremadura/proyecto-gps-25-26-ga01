import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports de tu proyecto
import 'package:audira_frontend/core/providers/auth_provider.dart';
import 'package:audira_frontend/core/providers/cart_provider.dart';
import 'package:audira_frontend/core/providers/library_provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/album.dart';

class AlbumCard extends StatelessWidget {
  final Album album;

  const AlbumCard({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160, // Ancho fijo ligeramente ajustado para grid
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Usamos Material y InkWell para el efecto ripple nativo
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, '/album', arguments: album.id);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------
              // SECCIÓN DE IMAGEN Y BADGE
              // ---------------------------------------------------------
              Stack(
                children: [
                  // 1. Imagen con Hero Animation
                  Hero(
                    tag: 'album-${album.id}',
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: album.coverImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: album.coverImageUrl!,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppTheme.surfaceBlack,
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppTheme.surfaceBlack,
                                child: Icon(Icons.album,
                                    size: 40,
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                            )
                          : Container(
                              height: 140,
                              width: double.infinity,
                              color: AppTheme.surfaceBlack,
                              child: Icon(Icons.album,
                                  size: 40,
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                    ),
                  ),

                  // 2. Sombra degradada para que el badge resalte
                  Positioned(
                    top: 0,
                    right: 0,
                    left: 0,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Badge de Estado (Comprado / Añadir al carrito)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildActionBadge(context),
                  ),
                ],
              ),

              // ---------------------------------------------------------
              // SECCIÓN DE INFORMACIÓN
              // ---------------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      album.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Precios
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Precio Actual
                        Text(
                          '\$${album.discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Precio Original (si hay descuento)
                        if (album.price > album.discountedPrice)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text(
                              '\$${album.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                decoration: TextDecoration.lineThrough,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionBadge(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, child) {
        final isPurchased = libraryProvider.isAlbumPurchased(album.id);

        if (isPurchased) {
          // BADGE: COMPRADO
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Comprado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ).animate().scale();
        }

        // BADGE: BOTÓN CARRITO
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleAddToCart(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue, // Fondo azul semitransparente
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 6)
                ],
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2), width: 1),
              ),
              child: const Icon(
                Icons.add_shopping_cart_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para comprar'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final success = await cartProvider.addToCart(
      userId: authProvider.currentUser!.id,
      itemType: 'ALBUM',
      itemId: album.id,
      price: album.discountedPrice,
      quantity: 1,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${album.name} añadido al carrito'
                : 'Ya está en el carrito',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: success ? AppTheme.successGreen : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
