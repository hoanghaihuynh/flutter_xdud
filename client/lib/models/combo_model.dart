import 'dart:convert';

import 'package:myproject/models/combo_product_config_item.dart';

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
  final List<String> toppings;
  final DateTime? createdAt;
  final int? v;

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

class ComboProductItemInput {
  final String productId;
  final int quantityInCombo;
  final String defaultSize;
  final String defaultSugarLevel;
  final List<String> defaultToppings; // Danh sách ID của topping

  ComboProductItemInput({
    required this.productId,
    required this.quantityInCombo,
    required this.defaultSize,
    required this.defaultSugarLevel,
    required this.defaultToppings,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantityInCombo': quantityInCombo,
      'defaultSize': defaultSize,
      'defaultSugarLevel': defaultSugarLevel,
      'defaultToppings': defaultToppings,
    };
  }
}

class Combo {
  final String id;
  final String name;
  final String description;
  final double price; // JSON là int, nhưng double linh hoạt hơn ở Dart
  final List<ComboProductConfigItem> products;
  final String imageUrl;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? v; // __v có thể không luôn luôn cần thiết

  Combo({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.products,
    required this.imageUrl,
    required this.category,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.v,
  });

  factory Combo.fromJson(Map<String, dynamic> json) {
    var productListJson = json['products'] as List<dynamic>? ?? [];
    List<ComboProductConfigItem> productsData = productListJson
        .map((pJson) =>
            ComboProductConfigItem.fromJson(pJson as Map<String, dynamic>))
        .toList();

    DateTime _parseSafeDateTime(String? dateString, {DateTime? defaultValue}) {
      if (dateString == null || dateString.isEmpty) {
        return defaultValue ??
            DateTime.now(); // Hoặc throw lỗi nếu trường này bắt buộc
      }
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print("Error parsing date string '$dateString': $e");
        return defaultValue ?? DateTime.now(); // Fallback
      }
    }

    return Combo(
      id: json['_id'] as String? ?? '', // Luôn xử lý null
      name: json['name'] as String? ?? 'Unknown Combo',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      products: productsData,
      imageUrl:
          json['imageUrl'] as String? ?? 'https://via.placeholder.com/200',
      category: json['category'] as String? ?? 'N/A',
      isActive: json['isActive'] as bool? ?? false,
      createdAt: _parseSafeDateTime(json['createdAt'] as String?),
      updatedAt: _parseSafeDateTime(json['updatedAt'] as String?),
      v: json['__v'] as int?,
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

class DeleteResponseMessage {
  final String message;

  DeleteResponseMessage({required this.message});

  factory DeleteResponseMessage.fromJson(Map<String, dynamic> json) {
    return DeleteResponseMessage(
      message: json['message'] as String? ??
          'Operation successful', // Xử lý nếu message có thể null
    );
  }
}

// Hàm helper để parse response
DeleteResponseMessage parseDeleteResponseMessage(String responseBody) {
  final Map<String, dynamic> parsed = json.decode(responseBody);
  return DeleteResponseMessage.fromJson(parsed);
}

// Hàm helper để parse một danh sách các đối tượng Combo từ chuỗi JSON
List<Combo> parseCombos(String responseBody) {
  try {
    final parsed = json.decode(responseBody);
    if (parsed == null || parsed is! List) {
      // Kiểm tra null và kiểu List
      print(
          "Error: Expected a List of combos but received: ${parsed?.runtimeType}");
      return []; // Trả về rỗng nếu không phải List
    }
    return parsed
        .cast<Map<String, dynamic>>() // Ép kiểu từng phần tử sang Map
        .map<Combo>((jsonMap) => Combo.fromJson(jsonMap))
        .toList();
  } catch (e) {
    print("Error in parseCombos: $e");
    print("Response body that caused error: $responseBody");
    throw Exception('Failed to parse list of combos: $e');
  }
}
