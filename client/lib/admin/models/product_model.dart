class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final int stock;
  final String imageUrl;
  final List<String> toppings;
  final List<String> size;
  final List<String> sugarLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.stock,
    required this.imageUrl,
    required this.toppings,
    required this.size,
    required this.sugarLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      stock: json['stock'] ?? 0,
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/150',
      // Xử lý null cho các List
      toppings: json['toppings'] != null
          ? List<String>.from(json['toppings'].map((x) => x.toString()))
          : <String>[], // Trả về list rỗng nếu null
      size: json['size'] != null
          ? List<String>.from(json['size'])
          : <String>['M'], // Giá trị mặc định
      sugarLevel: json['sugarLevel'] != null
          ? List<String>.from(json['sugarLevel'])
          : <String>['0 SG'], // Giá trị mặc định
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'stock': stock,
      'imageUrl': imageUrl,
      'toppings': toppings,
      'size': size,
      'sugarLevel': sugarLevel,
    };
  }
}
