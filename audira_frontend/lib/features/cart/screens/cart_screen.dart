import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Importante para las animaciones
import '../../../config/theme.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/order_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../checkout/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService _orderService = OrderService();
  bool _isCreatingOrder = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await cartProvider.loadCart(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isEmpty =
        cartProvider.cart == null || cartProvider.cart!.items.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Column(
        children: [
          // Área principal con Scroll (Header + Lista)
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header estilo StoreScreen
                SliverAppBar(
                  backgroundColor: AppTheme.backgroundBlack,
                  surfaceTintColor: Colors.transparent,
                  floating: true,
                  pinned: true,
                  snap: true,
                  expandedHeight: 80,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.darkBlue.withValues(alpha: 0.3),
                            AppTheme.backgroundBlack
                          ],
                        ),
                      ),
                    ),
                  ),
                  title: const Text(
                    'TU CARRITO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 16,
                    ),
                  ),
                  centerTitle: true,
                ),

                // 2. Contenido (Empty State o Lista)
                if (isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: AppTheme.textGrey.withValues(alpha: 0.3),
                          ).animate().scale(duration: 500.ms),
                          const SizedBox(height: 16),
                          const Text(
                            'Tu carrito está vacío',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 8),
                          const Text(
                            'Explora la tienda para agregar música',
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 14,
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final itemDetail =
                              cartProvider.cartItemDetails[index];
                          return _buildCartItemTile(
                            context,
                            itemDetail,
                            cartProvider,
                            authProvider,
                          )
                              .animate(delay: (50 * index).ms)
                              .fadeIn()
                              .slideX(begin: 0.1, end: 0);
                        },
                        childCount: cartProvider.cartItemDetails.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. Footer de Totales (Fijo abajo si hay items)
          if (!isEmpty)
            _buildCheckoutFooter(context, cartProvider, authProvider),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(
    BuildContext context,
    dynamic itemDetail, // Usar el tipo correcto si está disponible
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    final item = itemDetail.cartItem;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen del producto
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: itemDetail.itemImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: itemDetail.itemImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, error) => Icon(
                          item.itemType == 'SONG'
                              ? Icons.music_note
                              : Icons.album,
                          color: AppTheme.textGrey,
                        ),
                      )
                    : Icon(
                        item.itemType == 'SONG'
                            ? Icons.music_note
                            : Icons.album,
                        color: AppTheme.textGrey,
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemDetail.itemName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemDetail.itemArtist,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Tipo de ítem (badge pequeña)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.itemType == 'SONG' ? 'Canción' : 'Álbum',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Precio y Botón Eliminar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _confirmDelete(
                      context, itemDetail, item, cartProvider, authProvider),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.errorRed.withValues(alpha: 0.8),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutFooter(
    BuildContext context,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Resumen de costos
            _buildSummaryRow('Subtotal', cartProvider.subtotal),
            const SizedBox(height: 8),
            _buildSummaryRow('IVA (21%)', cartProvider.taxAmount,
                isSecondary: true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white10),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '\$${cartProvider.totalWithTax.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botón de Pago
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isCreatingOrder
                      ? null
                      : () => _proceedToCheckout(cartProvider, authProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
                  ),
                  child: _isCreatingOrder
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'PROCEDER AL PAGO',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ).animate().shimmer(duration: 2000.ms, delay: 1000.ms),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool isSecondary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isSecondary ? AppTheme.textGrey : Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isSecondary ? AppTheme.textGrey : Colors.white,
            fontSize: 14,
            fontWeight: isSecondary ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Lógica de eliminación (Sin cambios funcionales, solo UI del dialogo actualizada)
  void _confirmDelete(
    BuildContext context,
    dynamic itemDetail,
    dynamic item,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    if (authProvider.currentUser != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('Eliminar producto',
              style: TextStyle(color: Colors.white)),
          content: Text(
            '¿Deseas eliminar "${itemDetail.itemName}" del carrito?',
            style: const TextStyle(color: AppTheme.textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final itemName = itemDetail.itemName;

                navigator.pop();

                final success = await cartProvider.removeItem(
                  authProvider.currentUser!.id,
                  item.id!,
                );

                if (success) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('$itemName eliminado'),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Error al eliminar'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              },
              child: const Text('Eliminar',
                  style: TextStyle(color: AppTheme.errorRed)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _proceedToCheckout(
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) async {
    if (!authProvider.isAuthenticated) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para comprar')),
      );
      return;
    }

    setState(() => _isCreatingOrder = true);

    try {
      final orderItems = cartProvider.cartItemDetails.map((itemDetail) {
        final item = itemDetail.cartItem;
        int? artistId;
        if (item.itemType == 'SONG' && itemDetail.song != null) {
          artistId = itemDetail.song!.artistId;
        } else if (item.itemType == 'ALBUM' && itemDetail.album != null) {
          artistId = itemDetail.album!.artistId;
        }

        return {
          'itemType': item.itemType,
          'itemId': item.itemId,
          'artistId': artistId,
          'quantity': item.quantity,
          'price': item.price,
        };
      }).toList();

      final response = await _orderService.createOrder(
        userId: authProvider.currentUser!.id,
        shippingAddress: 'Digital delivery',
        items: orderItems,
      );

      setState(() => _isCreatingOrder = false);

      if (response.success && response.data != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CheckoutScreen(order: response.data!),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error al crear la orden'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreatingOrder = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
