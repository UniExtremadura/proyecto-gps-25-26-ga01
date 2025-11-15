import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../api/services/cart_service.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../api/services/music_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final MusicService _musicService = MusicService();

  Cart? _cart;
  bool _isLoading = false;
  List<CartItemDetail> _cartItemDetails = [];

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  int get itemCount => _cart?.itemCount ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;
  List<CartItemDetail> get cartItemDetails => _cartItemDetails;

  static const double taxRate = 0.21;

  double get subtotal {
    if (_cart == null || _cart!.items.isEmpty) return 0.0;
    return _cart!.items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get taxAmount {
    return subtotal * taxRate;
  }

  double get totalWithTax {
    return subtotal + taxAmount;
  }

  Future<void> loadCart(int userId) async {
    _isLoading = true;
    notifyListeners();

    final response = await _cartService.getCart(userId);
    if (response.success && response.data != null) {
      _cart = response.data;
      await _loadCartItemDetails();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCartItemDetails() async {
    if (_cart == null || _cart!.items.isEmpty) {
      _cartItemDetails = [];
      return;
    }

    _cartItemDetails = [];
    for (var item in _cart!.items) {
      Song? song;
      Album? album;

      if (item.itemType == 'SONG') {
        final songResponse = await _musicService.getSongById(item.itemId);
        if (songResponse.success && songResponse.data != null) {
          song = songResponse.data;
        }
      } else if (item.itemType == 'ALBUM') {
        final albumResponse = await _musicService.getAlbumById(item.itemId);
        if (albumResponse.success && albumResponse.data != null) {
          album = albumResponse.data;
        }
      }

      _cartItemDetails.add(CartItemDetail(
        cartItem: item,
        song: song,
        album: album,
      ));
    }
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
      await _loadCartItemDetails();
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
      await _loadCartItemDetails();
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
