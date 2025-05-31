class ComboProductConfigItem {
  final String productId; // ID của Product gốc
  final int quantityInCombo;
  final String defaultSize;
  final String defaultSugarLevel;
  final List<String> defaultToppings; // Giả sử đây là danh sách tên topping hoặc ID topping (kiểu String)

  ComboProductConfigItem({
    required this.productId,
    required this.quantityInCombo,
    required this.defaultSize,
    required this.defaultSugarLevel,
    required this.defaultToppings,
  });

  factory ComboProductConfigItem.fromJson(Map<String, dynamic> json) {
    return ComboProductConfigItem(
      productId: json['productId'] as String? ?? '', // Xử lý null nếu có thể
      quantityInCombo: json['quantityInCombo'] as int? ?? 1,
      defaultSize: json['defaultSize'] as String? ?? 'M', // Cung cấp giá trị mặc định
      defaultSugarLevel: json['defaultSugarLevel'] as String? ?? '100%', // Cung cấp giá trị mặc định
      defaultToppings: (json['defaultToppings'] as List<dynamic>?)
              ?.map((topping) => topping.toString()) // Đảm bảo mỗi topping là String
              .toList() ??
          [],
    );
  }

  // toJson nếu cần (ví dụ khi gửi dữ liệu lên server để tạo/sửa combo)
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