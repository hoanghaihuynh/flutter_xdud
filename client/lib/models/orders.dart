// models/order.dart
import './payment.dart';

class Order {
  final String id;
  final User user;
  final List<ProductItem> products;
  final double total;
  final String status;
  final DateTime createdAt;
  final String? paymentMethod;
  final PaymentInfo? paymentInfo;

  Order({
    required this.id,
    required this.user,
    required this.products,
    required this.total,
    required this.status,
    required this.createdAt,
    this.paymentMethod,
    this.paymentInfo,
  });
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      user: User.fromJson(json['user_id']),
      products: List<ProductItem>.from(
          json['products'].map((x) => ProductItem.fromJson(x))),
      total: json['total'].toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),

      // ✅ Parse thêm
      paymentMethod: json['payment_method'],
      paymentInfo: json['paymentInfo'] != null
          ? PaymentInfo.fromJson(json['paymentInfo'])
          : null,
    );
  }
}

class User {
  final String id;
  final String email;

  User({required this.id, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      email: json['email'],
    );
  }
}

class ProductItem {
  final Product product;
  final int quantity;
  final double price;
  final String id;

  ProductItem({
    required this.product,
    required this.quantity,
    required this.price,
    required this.id,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      product: Product.fromJson(json['product_id']),
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      id: json['_id'],
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      price: json['price'].toDouble(),
    );
  }
}
