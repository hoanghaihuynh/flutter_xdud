class Topping {
  final String id;
  final String name;
  final double price;
  final String description;

  Topping({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });

  factory Topping.fromJson(Map<String, dynamic> json) {
    return Topping(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'description': description,
    };
  }

  // Hỗ trợ copyWith để cập nhật từng phần
  Topping copyWith({
    String? name,
    double? price,
    String? description,
  }) {
    return Topping(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
    );
  }
}