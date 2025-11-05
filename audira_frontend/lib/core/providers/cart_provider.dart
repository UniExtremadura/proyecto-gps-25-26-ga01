import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../api/services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  Cart? _cart;
  bool _isLoading = false;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  int get itemCount => _cart?.itemCount ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;

  Future<void> loadCart(int userId) async {
    _isLoading = true;
    notifyListeners();

    final response = await _cartService.getCart(userId);
    if (response.success && response.data != null) {
      _cart = response.data;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addToCart({
    required int userId,
    required String itemType,
    required int itemId,
    required double price,
    int quantity = 1,
  }) async {
    final response = await _cartService.addToCart(
      userId: userId,
      itemType: itemType,
      itemId: itemId,
      price: price,
      quantity: quantity,
    );

    if (response.success && response.data != null) {
      _cart = response.data;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateQuantity(int userId, int itemId, int quantity) async {
    final response = await _cartService.updateCartItem(
      userId: userId,
      itemId: itemId,
      quantity: quantity,
    );

    if (response.success && response.data != null) {
      _cart = response.data;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> removeItem(int userId, int itemId) async {
    final response = await _cartService.removeFromCart(userId, itemId);
    if (response.success) {
      await loadCart(userId);
      return true;
    }
    return false;
  }

  Future<void> clearCart(int userId) async {
    await _cartService.clearCart(userId);
    _cart = null;
    notifyListeners();
  }
}
