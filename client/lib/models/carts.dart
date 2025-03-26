// class CartResponse {
//   final String success;
//   final CartData data;

//   CartResponse({
//     required this.success,
//     required this.data,
//   });

//   factory CartResponse.fromJson(Map<String, dynamic> json) {
//     return CartResponse(
//       success: json['success'],
//       data: CartData.fromJson(json['data']),
//     );
//   }
// }

// class CartData {
//   final String id;
//   final String userId;
//   final List<CartProduct> products;
//   final int totalPrice;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final int v;

//   CartData({
//     required this.id,
//     required this.userId,
//     required this.products,
//     required this.totalPrice,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.v,
//   });

//   factory CartData.fromJson(Map<String, dynamic> json) {
//     return CartData(
//       id: json['_id'],
//       userId: json['userId'],
//       products: List<CartProduct>.from(
//           json['products'].map((x) => CartProduct.fromJson(x))),
//       totalPrice: json['totalPrice'],
//       createdAt: DateTime.parse(json['createdAt']),
//       updatedAt: DateTime.parse(json['updatedAt']),
//       v: json['__v'],
//     );
//   }
// }

// class CartProduct {
//   final Product productId;
//   final int quantity;
//   final int price;
//   final String id;

//   CartProduct({
//     required this.productId,
//     required this.quantity,
//     required this.price,
//     required this.id,
//   });

//   factory CartProduct.fromJson(Map<String, dynamic> json) {
//     return CartProduct(
//       productId: Product.fromJson(json['productId']),
//       quantity: json['quantity'],
//       price: json['price'],
//       id: json['_id'],
//     );
//   }
// }

// class Product {
//   final String imageUrl;
//   final String id;
//   final String name;
//   final int price;
//   final String description;
//   final String category;
//   final int stock;
//   final DateTime updatedAt;

//   Product({
//     required this.imageUrl,
//     required this.id,
//     required this.name,
//     required this.price,
//     required this.description,
//     required this.category,
//     required this.stock,
//     required this.updatedAt,
//   });

//   factory Product.fromJson(Map<String, dynamic> json) {
//     return Product(
//       imageUrl: json['imageUrl'],
//       id: json['_id'],
//       name: json['name'],
//       price: json['price'],
//       description: json['description'],
//       category: json['category'],
//       stock: json['stock'],
//       updatedAt: DateTime.parse(json['updatedAt']),
//     );
//   }
// }

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
