class ComboProductConfig {
  final String productId; // ID của sản phẩm
  String productName; // Tên sản phẩm (để hiển thị, sẽ được lấy từ ProductModel)
  int quantityInCombo;
  String defaultSize;
  String defaultSugarLevel;
  List<String> defaultToppingIds; // Danh sách ID của các topping mặc định

  ComboProductConfig({
    required this.productId,
    this.productName = '', // Sẽ được cập nhật sau khi chọn sản phẩm
    this.quantityInCombo = 1,
    required this.defaultSize,
    required this.defaultSugarLevel,
    this.defaultToppingIds = const [],
  });

  // toJson để gửi lên backend (khớp với ComboProductItemSchema)
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantityInCombo': quantityInCombo,
      'defaultSize': defaultSize,
      'defaultSugarLevel': defaultSugarLevel,
      'defaultToppings': defaultToppingIds, // Gửi mảng ID topping
    };
  }

  // fromJson để đọc từ ComboModel (nếu ComboModel.products là List<ComboProductConfig>)
  // Giả sử backend trả về ComboProductItemSchema với productId là String (ID)
  factory ComboProductConfig.fromJson(Map<String, dynamic> json, {String? fetchedProductName}) {
    return ComboProductConfig(
      productId: json['productId'] as String? ?? '',
      productName: fetchedProductName ?? json['productName'] as String? ?? 'N/A', // Ưu tiên tên đã fetch, sau đó đến tên trong json (nếu có)
      quantityInCombo: (json['quantityInCombo'] as num?)?.toInt() ?? 1,
      defaultSize: json['defaultSize'] as String? ?? 'M', // Cần giá trị mặc định hợp lệ
      defaultSugarLevel: json['defaultSugarLevel'] as String? ?? '0 SL', // Cần giá trị mặc định hợp lệ
      defaultToppingIds: json['defaultToppings'] != null
          ? List<String>.from(json['defaultToppings'].map((x) => x.toString()))
          : <String>[],
    );
  }
}