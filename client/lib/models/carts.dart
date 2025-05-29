class CartItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;
  final String size;
  final String sugarLevel;
  final List<String> toppings;
  final double toppingPrice; // Giá topping

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.size,
    required this.sugarLevel,
    required this.toppings,
    this.toppingPrice = 0.0,
  });

  // Tính tổng giá cho item (giá sản phẩm + topping) * số lượng
  double get totalPrice => (price + toppingPrice) * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] ?? '',
      productId: json['productId'] is String
          ? json['productId']
          : json['productId']['_id'] ?? '',
      name: json['productId'] is String
          ? 'Unknown Product'
          : json['productId']['name'] ?? 'Unknown Product',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['productId'] is String
          ? 'https://via.placeholder.com/150'
          : json['productId']['imageUrl'] ?? 'https://via.placeholder.com/150',
      size: json['note']?['size'] ?? 'M',
      sugarLevel: json['note']?['sugarLevel'] ?? '50 SL',
      toppings: List<String>.from(json['note']?['toppings'] ?? []),
      toppingPrice: (json['toppingPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        'price': price,
        'note': {
          'size': size,
          'sugarLevel': sugarLevel,
          'toppings': toppings,
        },
        'toppingPrice': toppingPrice,
      };
}

// Model cho toàn bộ giỏ hàng (Cart) có voucher
class Cart {
  final List<CartItem> items;
  final double totalPrice;
  final String? voucherCode;       // Mã voucher (có thể null)
  final double discountAmount;     // Số tiền giảm giá
  final double finalPrice;         // Giá sau khi trừ voucher

  Cart({
    required this.items,
    required this.totalPrice,
    this.voucherCode,
    this.discountAmount = 0,
    required this.finalPrice,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    var itemsJson = json['products'] as List<dynamic>? ?? [];
    List<CartItem> items = itemsJson.map((item) => CartItem.fromJson(item)).toList();

    double totalPrice = (json['totalPrice'] ?? 0).toDouble();
    String? voucherCode = json['voucher_code'];
    double discountAmount = (json['discount_amount'] ?? 0).toDouble();

    double finalPrice = totalPrice - discountAmount;

    return Cart(
      items: items,
      totalPrice: totalPrice,
      voucherCode: voucherCode,
      discountAmount: discountAmount,
      finalPrice: finalPrice < 0 ? 0 : finalPrice,
    );
  }

  Map<String, dynamic> toJson() => {
        'products': items.map((item) => item.toJson()).toList(),
        'totalPrice': totalPrice,
        'voucher_code': voucherCode,
        'discount_amount': discountAmount,
        'finalPrice': finalPrice,
      };
}
