import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Tu carrito está vacío',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega productos para comenzar',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textGrey,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartProvider.cart!.items.length,
            itemBuilder: (context, index) {
              final item = cartProvider.cart!.items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text('${item.itemType} #${item.itemId}'),
                  subtitle: Text(
                    '\$${item.price.toStringAsFixed(2)} x ${item.quantity}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (item.quantity > 1 &&
                              authProvider.currentUser != null) {
                            cartProvider.updateQuantity(
                              authProvider.currentUser!.id,
                              item.id!,
                              item.quantity - 1,
                            );
                          }
                        },
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (authProvider.currentUser != null) {
                            cartProvider.updateQuantity(
                              authProvider.currentUser!.id,
                              item.id!,
                              item.quantity + 1,
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.errorRed,
                        onPressed: () {
                          if (authProvider.currentUser != null) {
                            cartProvider.removeItem(
                              authProvider.currentUser!.id,
                              item.id!,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlack,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '\$${cartProvider.totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (!authProvider.isAuthenticated) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Debes iniciar sesión para comprar',
                          ),
                        ),
                      );
                    } else {
                      // Proceed to checkout
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad de pago próximamente'),
                        ),
                      );
                    }
                  },
                  child: const Text('Proceder al pago'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
