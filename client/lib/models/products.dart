import 'package:myproject/models/combo_model.dart';
import 'package:myproject/models/combo_product_config_item.dart';

class Product {
  final String id;
  final String name;
  final double price; // Đối với combo, đây là giá của COMBO
  final String description;
  final String category; // Đối với combo, category sẽ được gán là "Combo"
  final int
      stock; // Đối với combo, stock có thể hiểu là số lượng combo có thể bán
  final String imageUrl;
  final List<String>
      sizes; // Đối với combo, trường này có thể là danh sách rỗng
  final List<String>
      sugarLevels; // Đối với combo, trường này có thể là danh sách rỗng
  final List<String>
      toppingIds; // Đối với combo, trường này có thể là danh sách rỗng

  // --- THÊM CÁC TRƯỜNG SAU ---
  final bool isCombo;
  final List<ComboProductConfigItem>?
      detailedComboItems; // Danh sách các sản phẩm con trong combo

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
    this.isCombo = false, // Giá trị mặc định
    this.detailedComboItems, // Giá trị mặc định là null
  });

  // Factory constructor này dùng để parse sản phẩm THƯỜNG từ API
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0, // An toàn hơn với num?
      description: json['description'] ?? '',
      category: json['category'] ??
          'Coffee', // Gán category mặc định nếu API không trả về
      stock: json['stock'] ?? 0,
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/150',
      sizes: List<String>.from(json['size'] as List<dynamic>? ??
          ['M']), // Xử lý an toàn nếu 'size' là null
      sugarLevels: List<String>.from(
          json['sugarLevel'] as List<dynamic>? ?? ['50 SL']), // Xử lý an toàn
      toppingIds: (json['toppings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isCombo:
          false, // Quan trọng: Sản phẩm parse từ API sản phẩm thường thì isCombo = false
      detailedComboItems: null, // Không có chi tiết combo cho sản phẩm thường
    );
  }

  // --- THÊM FACTORY CONSTRUCTOR NÀY ---
  // Factory constructor để tạo đối tượng Product đại diện cho một COMBO
  // từ đối tượng Combo (mà bạn parse từ API combo, ví dụ class Combo trong combo_model.dart)
  factory Product.fromApiCombo(Combo apiCombo) {
    // Combo ở đây là class Combo từ combo_model.dart
    return Product(
      id: apiCombo.id, // ID của combo
      name: apiCombo.name, // Tên của combo
      price: apiCombo.price, // Giá của combo
      description: apiCombo.description, // Mô tả của combo
      category: 'Combo', // Gán category là 'Combo' cho dễ lọc
      imageUrl: apiCombo.imageUrl, // Ảnh của combo
      stock: 0, // Hoặc bạn có thể có logic tính stock cho combo nếu cần
      sizes: [], // Combo thường không có size/sugar/topping ở cấp độ cha
      sugarLevels: [],
      toppingIds: [],
      isCombo: true, // Quan trọng: Đánh dấu đây là combo
      detailedComboItems:
          apiCombo.products, // Gán danh sách ProductItem từ Combo API
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
        // --- THÊM CÁC TRƯỜNG SAU KHI SERIALIZE ---
        'isCombo': isCombo,
        'detailedComboItems':
            detailedComboItems?.map((item) => item.toJson()).toList(),
        // Lưu ý: ProductItem cũng cần có phương thức toJson()
      };
}

// Danh sách categories của bạn có thể giữ nguyên
const List<String> productCategories = [
  'All',
  'Combo',
  'Coffee',
  'Tea',
  'Smoothies',
  'Pastries',
];
