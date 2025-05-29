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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CartItem({
    this.id = '',
    required this.productId,
    this.name = 'Unknown Product',
    required this.price,
    this.quantity = 1,
    this.imageUrl = 'https://via.placeholder.com/150',
    this.size = 'M',
    this.sugarLevel = '50%',
    this.toppings = const [],
    this.toppingPrice = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  double get totalPrice => (price + toppingPrice) * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Handle productId when it's either String or Map
    final productInfo = json['productId'] is String
        ? {'_id': json['productId']}
        : json['productId'] as Map<String, dynamic>? ?? {};

    // Handle note with default values
    final note = json['note'] as Map<String, dynamic>? ?? {};

    // Parse dates safely
    final createdAt = json['createdAt'] != null 
        ? DateTime.tryParse(json['createdAt'].toString()) 
        : null;
    final updatedAt = json['updatedAt'] != null 
        ? DateTime.tryParse(json['updatedAt'].toString()) 
        : null;

    return CartItem(
      id: json['_id']?.toString() ?? '',
      productId: productInfo['_id']?.toString() ?? '',
      name: productInfo['name']?.toString() ?? 'Unknown Product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: productInfo['imageUrl']?.toString() ?? 
          'https://via.placeholder.com/150',
      size: note['size']?.toString() ?? 'M',
      sugarLevel: note['sugarLevel']?.toString() ?? '50%',
      toppings: List<String>.from(note['toppings'] ?? []),
      toppingPrice: (json['toppingPrice'] as num?)?.toDouble() ?? 0.0,
      createdAt: createdAt,
      updatedAt: updatedAt,
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

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
    String? size,
    String? sugarLevel,
    List<String>? toppings,
    double? toppingPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      toppings: toppings ?? List.from(this.toppings),
      toppingPrice: toppingPrice ?? this.toppingPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId &&
          name == other.name &&
          price == other.price &&
          quantity == other.quantity &&
          imageUrl == other.imageUrl &&
          size == other.size &&
          sugarLevel == other.sugarLevel &&
          toppings.toString() == other.toppings.toString() &&
          toppingPrice == other.toppingPrice;

  @override
  int get hashCode =>
      id.hashCode ^
      productId.hashCode ^
      name.hashCode ^
      price.hashCode ^
      quantity.hashCode ^
      imageUrl.hashCode ^
      size.hashCode ^
      sugarLevel.hashCode ^
      toppings.hashCode ^
      toppingPrice.hashCode;
}

class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalPrice;
  final String? voucherCode;
  final double discountAmount;
  final double finalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    this.voucherCode,
    this.discountAmount = 0.0,
    this.finalPrice = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    // Parse dates safely
    final createdAt = DateTime.parse(json['createdAt'].toString());
    final updatedAt = DateTime.parse(json['updatedAt'].toString());

    // Calculate final price if not provided
    final totalPrice = json['totalPrice']?.toDouble() ?? 0.0;
    final discountAmount = json['discountAmount']?.toDouble() ?? 0.0;
    final finalPrice = json['finalPrice']?.toDouble() ?? 
        (totalPrice - discountAmount).clamp(0, double.infinity);

    return Cart(
      id: json['_id'].toString(),
      userId: json['userId'] is String
          ? json['userId'].toString()
          : (json['userId'] as Map<String, dynamic>)['_id']?.toString() ?? '',
      items: (json['products'] as List?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalPrice: totalPrice,
      voucherCode: json['voucherCode']?.toString(),
      discountAmount: discountAmount,
      finalPrice: finalPrice,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'products': items.map((item) => item.toJson()).toList(),
        'totalPrice': totalPrice,
        if (voucherCode != null) 'voucherCode': voucherCode,
        'discountAmount': discountAmount,
        'finalPrice': finalPrice,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Cart copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    double? totalPrice,
    String? voucherCode,
    double? discountAmount,
    double? finalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? List.from(this.items),
      totalPrice: totalPrice ?? this.totalPrice,
      voucherCode: voucherCode ?? this.voucherCode,
      discountAmount: discountAmount ?? this.discountAmount,
      finalPrice: finalPrice ?? this.finalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}