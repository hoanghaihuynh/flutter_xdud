// File: models/inserted_combo_data.dart (hoặc bạn có thể đặt chung với các model khác)
// (Nếu bạn đã có file combo_model.dart, có thể không cần tạo file mới này
//  mà điều chỉnh/thêm class này vào đó, nhưng đảm bảo tên class không trùng)

import 'dart:convert';

class InsertedComboData {
  final String id; // Tương ứng với "_id"
  final String name;
  final String description;
  final double price;
  final List<String> products; // Danh sách các Product ID
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v; // Tương ứng với "__v"

  InsertedComboData({
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

  factory InsertedComboData.fromJson(Map<String, dynamic> json) {
    return InsertedComboData(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(), // Chuyển num sang double
      products: (json['products'] as List<dynamic>)
          .map((item) => item.toString()) // Đảm bảo các phần tử là String
          .toList(),
      imageUrl: json['imageUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      v: json['__v'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'price': price,
      'products': products,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }
}

// Hàm helper để parse response
InsertedComboData parseInsertedComboData(String responseBody) {
  final Map<String, dynamic> parsed = json.decode(responseBody);
  return InsertedComboData.fromJson(parsed);
}