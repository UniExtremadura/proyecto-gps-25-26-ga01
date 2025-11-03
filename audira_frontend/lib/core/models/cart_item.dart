import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final int? id;
  final int? cartId;
  final String itemType; // SONG, ALBUM
  final int itemId;
  final int quantity;
  final double price;

  const CartItem({
    this.id,
    this.cartId,
    required this.itemType,
    required this.itemId,
    this.quantity = 1,
    required this.price,
  });

  double get totalPrice => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int?,
      cartId: json['cartId'] as int?,
      itemType: json['itemType'] as String,
      itemId: json['itemId'] as int,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cartId': cartId,
      'itemType': itemType,
      'itemId': itemId,
      'quantity': quantity,
      'price': price,
    };
  }

  CartItem copyWith({
    int? id,
    int? cartId,
    String? itemType,
    int? itemId,
    int? quantity,
    double? price,
  }) {
    return CartItem(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  @override
  List<Object?> get props => [id, cartId, itemType, itemId, quantity, price];
}

class Cart extends Equatable {
  final int? id;
  final int userId;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Cart({
    this.id,
    required this.userId,
    this.items = const [],
    this.totalAmount = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Cart copyWith({
    int? id,
    int? userId,
    List<CartItem>? items,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, items, totalAmount, createdAt, updatedAt];
}
