class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final int stock;
  final String imageUrl;
  final List<String> sizes;
  final List<String> sugarLevels;
  final List<String> toppingIds; // Danh sách ID topping

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.stock,
    required this.imageUrl,
    required this.sizes,
    required this.sugarLevels,
    required this.toppingIds,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      price: json['price']?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      category: json['category'] ?? 'Coffee',
      stock: json['stock'] ?? 0,
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/150',
      sizes: List<String>.from(json['size'] ?? ['M']),
      sugarLevels: List<String>.from(json['sugarLevel'] ?? ['50 SL']),
      toppingIds: (json['toppings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              ?.toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'price': price,
        'description': description,
        'category': category,
        'stock': stock,
        'imageUrl': imageUrl,
        'size': sizes,
        'sugarLevel': sugarLevels,
        'toppings': toppingIds,
      };
}

// Danh sách categories có thể tách ra file riêng
const List<String> productCategories = [
  'All',
  'Combo',
  'Coffee',
  'Tea',
  'Smoothies',
  'Pastries',
];
