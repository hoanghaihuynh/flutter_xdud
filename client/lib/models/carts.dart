class CartItem {
  final String id; 
  final String productId; 
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
      productId: json['productId']['_id'], 
      name: json['productId']['name'],
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['productId']['imageUrl'] ?? 'https://via.placeholder.com/150',
    );
  }
}
