class CartItem {
  final String id; // ID của cart item (67e2e4ca0f56bc50c30f442f)
  final String productId; // ID thực của sản phẩm (67e2da3bb98bfed78d22ec1d)
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'],
      productId: json['productId']['_id'], // Lấy ID sản phẩm thực
      name: json['productId']['name'],
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['productId']['imageUrl'] ?? 'https://via.placeholder.com/150',
    );
  }
}
