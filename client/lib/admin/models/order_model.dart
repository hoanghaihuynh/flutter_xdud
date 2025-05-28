// import './payment_model.dart';
import './../../models/orders.dart';

class Order {
  final String id;
  final User user;
  final List<OrderProduct> products;
  final double total;
  final String status;
  final DateTime createdAt;
  final String? paymentMethod;

  Order({
    required this.id,
    required this.user,
    required this.products,
    required this.total,
    required this.status,
    required this.createdAt,
    this.paymentMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      return Order(
        id: json['_id'] ?? '',
        user: User.fromJson(json['user_id'] ?? {}),
        products: List<OrderProduct>.from((json['products'] as List? ?? [])
            .map((x) => OrderProduct.fromJson(x))),
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        status: json['status']?.toString() ?? 'pending',
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
        paymentMethod: json['payment_method']?.toString(),
      );
    } catch (e) {
      print('Error parsing Order: $e\nJSON: $json');
      rethrow;
    }
  }

  Order copyWith({
    String? status,
    String? paymentMethod,
  }) {
    return Order(
      id: id,
      user: user,
      products: products,
      total: total,
      status: status ?? this.status,
      createdAt: createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class OrderProduct {
  final Product product;
  final int quantity;
  final double price;
  final String id;
  final OrderNote note;

  OrderProduct({
    required this.product,
    required this.quantity,
    required this.price,
    required this.id,
    required this.note,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      product: Product.fromJson(json['product_id'] ?? {}),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      id: json['_id']?.toString() ?? '',
      note: OrderNote.fromJson(json['note'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': product.toJson(),
        'quantity': quantity,
        'price': price,
        '_id': id,
        'note': note.toJson(),
      };
}
