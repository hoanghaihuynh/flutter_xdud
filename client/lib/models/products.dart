class Products {
  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final int stock;
  final String imageUrl;

  Products({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.stock,
    required this.imageUrl,
  });

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      id: json['_id'],
      name: json['name'],
      price: json['price'].toDouble(),
      description: json['description'],
      category: json['category'],
      stock: json['stock'],
      imageUrl: json['imageUrl'] ?? "https://via.placeholder.com/150", // Giá trị mặc định nếu thiếu ảnh
    );
  }
}


List<String> categories = [
  'All',
  'Coffee',
  'Tea',
  'Smoothies',
  'Pastries',
];
