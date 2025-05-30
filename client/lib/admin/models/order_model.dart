import './../../models/orders.dart';
import '../../models/payment.dart';

class Order {
  final String id;
  final User user;
  final List<OrderProduct> products;
  final double total;
  final String status;
  final DateTime createdAt;
  final String? paymentMethod;
  final PaymentInfo? paymentInfo;
  final String? tableId; // <<--- THÊM TRƯỜNG NÀY
  final String? tableNumber; // <<--- THÊM TRƯỜNG NÀY

  Order({
    required this.id,
    required this.user,
    required this.products,
    required this.total,
    required this.status,
    required this.createdAt,
    this.paymentMethod,
    this.paymentInfo,
    this.tableId, // <<--- THÊM VÀO CONSTRUCTOR
    this.tableNumber, // <<--- THÊM VÀO CONSTRUCTOR
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      user: User.fromJson(json['user_id']),
      products: List<OrderProduct>.from(
          json['products'].map((x) => OrderProduct.fromJson(x))),
      total: (json['total'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      paymentMethod: json['payment_method'] as String?,
      paymentInfo: json['paymentInfo'] != null
          ? PaymentInfo.fromJson(json['paymentInfo'])
          : null,
      tableId: json['table_id'] as String?, // <<--- PARSE TỪ JSON
      tableNumber: json['table_number'] as String?, // <<--- PARSE TỪ JSON
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
