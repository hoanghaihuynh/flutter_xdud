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
  final double toppingPrice;
  final DateTime? createdAt; // Thêm trường thời gian
  final DateTime? updatedAt;

  CartItem({
    this.id = '',
    required this.productId,
    this.name = 'Unknown Product',
    required this.price,
    this.quantity = 1,
    this.imageUrl = 'https://via.placeholder.com/150',
    this.size = 'M',
    this.sugarLevel = '50 SG',
    this.toppings = const [],
    this.toppingPrice = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  double get totalPrice => (price + toppingPrice) * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Xử lý productId khi là object hoặc string
    final productInfo = json['productId'] is String 
        ? {'_id': json['productId']}
        : json['productId'] ?? {};
    
    // Xử lý note với giá trị mặc định
    final note = json['note'] ?? {};
    
    return CartItem(
      id: json['_id']?.toString() ?? '',
      productId: productInfo['_id']?.toString() ?? '',
      name: productInfo['name']?.toString() ?? 'Unknown Product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: productInfo['imageUrl']?.toString() ?? 'https://via.placeholder.com/150',
      size: note['size']?.toString() ?? 'M',
      sugarLevel: note['sugarLevel']?.toString() ?? '50 SG',
      toppings: List<String>.from(note['toppings'] ?? []),
      toppingPrice: (json['toppingPrice'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) '_id': id,
    'productId': productId,
    'quantity': quantity,
    'price': price,
    'note': {
      'size': size,
      'sugarLevel': sugarLevel,
      'toppings': toppings,
    },
    'toppingPrice': toppingPrice,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  // Tạo bản sao với các thuộc tính có thể thay đổi
  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
    String? size,
    String? sugarLevel,
    List<String>? toppings,
    double? toppingPrice,
  }) {
    return CartItem(
      id: id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      toppings: toppings ?? this.toppings,
      toppingPrice: toppingPrice ?? this.toppingPrice,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['_id'],
      userId: json['userId'] is String 
          ? json['userId'] 
          : json['userId']['_id'] ?? '',
      items: (json['products'] as List?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [],
      totalPrice: json['totalPrice']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}