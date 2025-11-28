import 'package:equatable/equatable.dart';
import 'payment.dart';
import 'order.dart';

class ReceiptItem extends Equatable {
  final String itemName;
  final String itemType;
  final int? itemId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const ReceiptItem({
    required this.itemName,
    required this.itemType,
    this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      itemName: json['itemName'] as String,
      itemType: json['itemType'] as String,
      itemId: json['itemId'] as int?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'itemType': itemType,
      'itemId': itemId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  ReceiptItem copyWith({
    String? itemName,
    String? itemType,
    int? itemId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return ReceiptItem(
      itemName: itemName ?? this.itemName,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  List<Object?> get props =>
      [itemName, itemType, itemId, quantity, unitPrice, totalPrice];
}

class Receipt extends Equatable {
  final String receiptNumber;
  final Payment payment;
  final Order order;
  final String customerName;
  final String customerEmail;
  final double subtotal;
  final double tax;
  final double total;
  final DateTime issuedAt;
  final List<ReceiptItem> items;

  const Receipt({
    required this.receiptNumber,
    required this.payment,
    required this.order,
    required this.customerName,
    required this.customerEmail,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.issuedAt,
    required this.items,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      receiptNumber: json['receiptNumber'] as String,
      payment: Payment.fromJson(json['payment'] as Map<String, dynamic>),
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
      customerName: json['customerName'] as String,
      customerEmail: json['customerEmail'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiptNumber': receiptNumber,
      'payment': payment.toJson(),
      'order': order.toJson(),
      'customerName': customerName,
      'customerEmail': customerEmail,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'issuedAt': issuedAt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  Receipt copyWith({
    String? receiptNumber,
    Payment? payment,
    Order? order,
    String? customerName,
    String? customerEmail,
    double? subtotal,
    double? tax,
    double? total,
    DateTime? issuedAt,
    List<ReceiptItem>? items,
  }) {
    return Receipt(
      receiptNumber: receiptNumber ?? this.receiptNumber,
      payment: payment ?? this.payment,
      order: order ?? this.order,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      issuedAt: issuedAt ?? this.issuedAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        receiptNumber,
        payment,
        order,
        customerName,
        customerEmail,
        subtotal,
        tax,
        total,
        issuedAt,
        items,
      ];
}
