// File: models/combo_model.dart

import 'dart:convert';

// Model cho một sản phẩm con bên trong một đối tượng Combo (từ API)
class ProductItem {
  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final int stock;
  final DateTime updatedAt;
  final String imageUrl;
  final List<String> size;
  final List<String> sugarLevel;
  final List<String> toppings; // Danh sách ID của topping
  final DateTime? createdAt; // Có thể có hoặc không trong API response
  final int? v; // __v, có thể có hoặc không

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.stock,
    required this.updatedAt,
    required this.imageUrl,
    required this.size,
    required this.sugarLevel,
    required this.toppings,
    this.createdAt,
    this.v,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['_id'] as String,
      name: json['name'] as String? ?? 'Unknown Product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      category:
          json['category'] as String? ?? 'N/A', // Hoặc giá trị mặc định khác
      stock: json['stock'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      imageUrl: json['imageUrl'] as String? ??
          'https://via.placeholder.com/150', // URL ảnh mặc định
      size:
          (json['size'] as List<dynamic>?)?.map((s) => s.toString()).toList() ??
              [], // Mặc định danh sách rỗng nếu null
      sugarLevel: (json['sugarLevel'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [], // Mặc định danh sách rỗng nếu null
      toppings: (json['toppings'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [], // Mặc định danh sách rỗng nếu null
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'stock': stock,
      'updatedAt': updatedAt.toIso8601String(),
      'imageUrl': imageUrl,
      'size': size,
      'sugarLevel': sugarLevel,
      'toppings': toppings,
      'createdAt': createdAt?.toIso8601String(),
      '__v': v,
    };
  }
}

// Model cho đối tượng Combo chính (từ API)
// Bạn có thể đặt tên là `ApiCombo` nếu muốn phân biệt rõ ràng hơn
// với class `Product` (đại diện combo) trong `ShopScreen`.
class Combo {
  final String id;
  final String name;
  final String description;
  final double price; // Giá của cả combo
  final List<ProductItem>
      products; // Danh sách các sản phẩm con (dùng ProductItem ở trên)
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v; // __v

  Combo({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.products,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory Combo.fromJson(Map<String, dynamic> json) {
    var productListJson = json['products'] as List<dynamic>? ??
        []; // Xử lý nếu 'products' có thể null
    List<ProductItem> productsData = productListJson
        .map((pJson) => ProductItem.fromJson(pJson as Map<String, dynamic>))
        .toList();

    return Combo(
      id: json['_id'] as String,
      name: json['name'] as String? ?? 'Unknown Combo',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      products: productsData,
      imageUrl: json['imageUrl'] as String? ??
          'https://via.placeholder.com/200', // URL ảnh mặc định cho combo
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      v: json['__v'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'price': price,
      'products': products.map((p) => p.toJson()).toList(),
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}

// Hàm helper để parse một danh sách các đối tượng Combo từ chuỗi JSON
List<Combo> parseCombos(String responseBody) {
  try {
    final parsed = json.decode(responseBody);
    if (parsed is List) {
      return parsed
          .cast<Map<String, dynamic>>()
          .map<Combo>((jsonMap) => Combo.fromJson(jsonMap))
          .toList();
    } else {
      // Xử lý trường hợp response không phải là một mảng JSON
      print("Error: Expected a List of combos but got ${parsed.runtimeType}");
      return []; // hoặc throw Exception('Invalid combo list format');
    }
  } catch (e) {
    print("Error parsing combos JSON: $e");
    throw Exception('Failed to parse combos: $e');
  }
}
