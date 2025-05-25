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
  final double toppingPrice; // Thêm trường giá topping

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
