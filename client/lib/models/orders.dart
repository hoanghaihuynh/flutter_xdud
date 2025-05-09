// models/order.dart
import './payment.dart';

class Order {
  final String id;
  final User user;
  final List<OrderProduct> products; // Đổi từ ProductItem sang OrderProduct
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
      products: List<OrderProduct>.from(
          json['products'].map((x) => OrderProduct.fromJson(x))),
      total: json['total'].toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
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

class OrderProduct {
  final Product product;
  final int quantity;
  final double price;
  final String id;
  final OrderNote note; // Thêm trường note

  OrderProduct({
    required this.product,
    required this.quantity,
    required this.price,
    required this.id,
    required this.note,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      product: Product.fromJson(json['product_id']),
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      id: json['_id'],
      note: OrderNote.fromJson(json['note'] ?? {}), // Xử lý khi note null
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

class OrderNote {
  final String size;
  final String sugarLevel;
  final List<String> toppings;
  final double toppingPrice;

  OrderNote({
    required this.size,
    required this.sugarLevel,
    required this.toppings,
    required this.toppingPrice,
  });

  factory OrderNote.fromJson(Map<String, dynamic> json) {
    return OrderNote(
      size: json['size'] ?? 'M', // Giá trị mặc định nếu null
      sugarLevel: json['sugarLevel'] ?? '50%', // Giá trị mặc định
      toppings: List<String>.from(json['toppings'] ?? []),
      toppingPrice: (json['toppingPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'size': size,
        'sugarLevel': sugarLevel,
        'toppings': toppings,
        'toppingPrice': toppingPrice,
      };
}

class Product {
  final String id;
  final String name;
  final double price;
  final String? imageUrl; // Thêm trường ảnh

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
      };
}