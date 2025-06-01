class ComboProductConfigItem {
  final String productId; // ID của Product gốc
  final String?
      productName; // Tên sản phẩm (để hiển thị ở UI, không gửi lên server qua toJson này)
  final int quantityInCombo;
  final String defaultSize;
  final String defaultSugarLevel;
  final List<String>
      defaultToppings; // Giả sử đây là danh sách tên topping hoặc ID topping (kiểu String)

  ComboProductConfigItem({
    required this.productId,
    this.productName, // Thêm productName
    required this.quantityInCombo,
    required this.defaultSize,
    required this.defaultSugarLevel,
    required this.defaultToppings,
  });

  factory ComboProductConfigItem.fromJson(Map<String, dynamic> json) {
    // Nếu API trả về thông tin sản phẩm được populate trong 'productId' field:
    String pId = '';
    String? pName; // Tên sản phẩm có thể lấy từ đây nếu API populate

    if (json['productId'] is Map<String, dynamic>) {
      // Giả sử API trả về productId là object đã populate
      pId = json['productId']['_id'] as String? ?? '';
      pName = json['productId']['name'] as String?; // Lấy tên nếu có
    } else if (json['productId'] is String) {
      // API chỉ trả về ID sản phẩm
      pId = json['productId'];
    }
    // Nếu API có trường productName riêng biệt ở cấp này của JSON (ít khả năng hơn dựa trên schema backend)
    // pName = pName ?? json['productName'] as String?;

    return ComboProductConfigItem(
      productId: pId,
      productName: pName, // Gán productName nếu có từ JSON
      quantityInCombo: json['quantityInCombo'] as int? ?? 1,
      defaultSize: json['defaultSize'] as String? ?? 'M',
      defaultSugarLevel: json['defaultSugarLevel'] as String? ??
          '50 SL', // Sửa giá trị mặc định
      defaultToppings: (json['defaultToppings'] as List<dynamic>?)
              ?.map((toppingId) =>
                  toppingId.toString()) // Đảm bảo mỗi topping ID là String
              .toList() ??
          [],
    );
  }

  // toJson nếu cần (ví dụ khi gửi dữ liệu lên server để tạo/sửa combo)
  Map<String, dynamic> toJson() {
    return {
      'productId': productId, // Chỉ gửi ID
      'quantityInCombo': quantityInCombo,
      'defaultSize': defaultSize,
      'defaultSugarLevel': defaultSugarLevel,
      'defaultToppings': defaultToppings, // Gửi danh sách ID topping
    };
  }

  ComboProductConfigItem copyWith({
    String? productId,
    String? productName,
    int? quantityInCombo,
    String? defaultSize,
    String? defaultSugarLevel,
    List<String>? defaultToppings,
  }) {
    return ComboProductConfigItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantityInCombo: quantityInCombo ?? this.quantityInCombo,
      defaultSize: defaultSize ?? this.defaultSize,
      defaultSugarLevel: defaultSugarLevel ?? this.defaultSugarLevel,
      defaultToppings: defaultToppings ?? this.defaultToppings,
    );
  }
}
