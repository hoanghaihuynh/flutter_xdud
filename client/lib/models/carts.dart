class CartItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;
  final String size;
  final String sugarLevel;
  final List<String> toppings;
  final double toppingPrice;
  final String? itemType; // Thêm trường này để biết loại item
  final String? comboId; // Thêm trường này để lưu comboId gốc nếu cần

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.size,
    required this.sugarLevel,
    required this.toppings,
    this.toppingPrice = 0.0,
    this.itemType,
    this.comboId,
  });

  // Tính tổng giá cho item (giá sản phẩm + topping) * số lượng
  double get totalPrice => (price + toppingPrice) * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    String type =
        json['itemType'] ?? 'PRODUCT'; // Mặc định là PRODUCT nếu không có

    if (type == 'COMBO') {
    // Lấy dữ liệu từ json['comboId'] (là một Map) một cách an toàn
    String actualComboIdString = '';
    String comboSpecificName = 'Unknown Combo Name from comboId'; // Tên từ trong object comboId
    // String comboSpecificImageUrl = 'https://via.placeholder.com/150'; // ImageUrl từ trong object comboId

    var comboDataMap = json['comboId'];
    if (comboDataMap is Map<String, dynamic>) {
      actualComboIdString = comboDataMap['_id'] ?? '';
      comboSpecificName = comboDataMap['name'] ?? comboSpecificName;
      // comboSpecificImageUrl = comboDataMap['imageUrl'] ?? comboSpecificImageUrl; // Nếu có imageUrl trong comboDataMap
    } else if (comboDataMap is String) { // Dự phòng nếu API thay đổi comboId thành String
        actualComboIdString = comboDataMap;
    }

    return CartItem(
      id: json['_id'] ?? '',
      productId: actualComboIdString, // Phải là String (ID của combo)
      name: json['name'] ?? comboSpecificName, // Ưu tiên name ở cấp ngoài, nếu không có thì lấy từ trong comboDataMap
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['imageUrl'] ?? 'https://via.placeholder.com/150', // Ưu tiên imageUrl ở cấp ngoài
      size: json['note']?['size'] ?? '',
      sugarLevel: json['note']?['sugarLevel'] ?? '',
      toppings: List<String>.from(json['note']?['toppings'] ?? []),
      toppingPrice: (json['toppingPrice'] ?? 0).toDouble(),
      itemType: type,
      comboId: actualComboIdString, // Gán ID String của combo, không phải Map
    );
    } else {
      // Mặc định là PRODUCT hoặc nếu itemType là PRODUCT
      String parsedId = json['_id'] ?? '';
      double parsedPrice = (json['price'] ?? 0).toDouble();
      int parsedQuantity = json['quantity'] ?? 1;
      String parsedSize = json['note']?['size'] ?? 'M';
      String parsedSugarLevel = json['note']?['sugarLevel'] ?? '50 SL';
      List<String> parsedToppings =
          List<String>.from(json['note']?['toppings'] ?? []);
      double parsedToppingPrice = (json['toppingPrice'] ?? 0).toDouble();

      String currentProductId = '';
      String currentName = 'Unknown Product';
      String currentImageUrl = 'https://via.placeholder.com/150';

      var productIdField =
          json['productId']; // Lấy giá trị của trường 'productId'

      if (productIdField is String) {
        // Trường hợp 1: productIdField là một chuỗi (ví dụ: "product_id_abc")
        currentProductId = productIdField;
        // Khi productId là String, ta thường lấy name và imageUrl từ cấp ngoài cùng của json item.
        // Cần đảm bảo các trường này là String để tránh lỗi type '_Map' is not subtype of 'String'.
        if (json['name'] is String) {
          currentName = json['name'];
        } else if (json['name'] != null) {
          // Nếu json['name'] tồn tại nhưng không phải String (ví dụ là Map)
          // Bạn cần quyết định cách xử lý, ở đây tạm để là "Invalid Name Data"
          // Hoặc bạn có thể thử lấy một giá trị mặc định từ Map đó nếu biết cấu trúc
          currentName = 'Invalid Name Data (Expected String)';
        }

        if (json['imageUrl'] is String) {
          currentImageUrl = json['imageUrl'];
        } else if (json['imageUrl'] != null) {
          currentImageUrl = 'Invalid Image URL (Expected String)';
        }
      } else if (productIdField is Map<String, dynamic>) {
        // Trường hợp 2: productIdField là một Map (ví dụ: {"_id": "123", "name": "abc", ...})
        currentProductId = productIdField['_id'] ?? '';
        currentName = productIdField['name'] ?? 'Unknown Product';
        currentImageUrl =
            productIdField['imageUrl'] ?? 'https://via.placeholder.com/150';
      }
      // Trường hợp 3: productIdField là null hoặc kiểu dữ liệu không mong muốn.
      // currentProductId, currentName, currentImageUrl sẽ giữ giá trị mặc định đã gán ở trên.
      print('Type of json: ${json.runtimeType}');
      print('json data: $json'); // In toàn bộ JSON của item đang xét

      print('Value for id: $parsedId, Type: ${parsedId.runtimeType}');
      print(
          'Value for productId: $currentProductId, Type: ${currentProductId.runtimeType}');
      print('Value for name: $currentName, Type: ${currentName.runtimeType}');
      print('Value for price: $parsedPrice, Type: ${parsedPrice.runtimeType}');
      print(
          'Value for quantity: $parsedQuantity, Type: ${parsedQuantity.runtimeType}');
      print(
          'Value for imageUrl: $currentImageUrl, Type: ${currentImageUrl.runtimeType}');
      print('Value for size: $parsedSize, Type: ${parsedSize.runtimeType}');
      print(
          'Value for sugarLevel: $parsedSugarLevel, Type: ${parsedSugarLevel.runtimeType}');
      print(
          'Value for toppings: $parsedToppings, Type: ${parsedToppings.runtimeType}');
      print(
          'Value for toppingPrice: $parsedToppingPrice, Type: ${parsedToppingPrice.runtimeType}');
      print('Value for itemType: $type, Type: ${type.runtimeType}');
      return CartItem(
        id: parsedId,
        productId: currentProductId,
        name: currentName,
        price: parsedPrice,
        quantity: parsedQuantity,
        imageUrl: currentImageUrl,
        size: parsedSize,
        sugarLevel: parsedSugarLevel,
        toppings: parsedToppings,
        toppingPrice: parsedToppingPrice,
        itemType: type,
        // comboId sẽ là null cho PRODUCT
      );
    }
  }

  Map<String, dynamic> toJson() {
    // Cần xem xét kỹ nếu bạn gửi CartItem ngược lại server,
    // hiện tại chỉ dùng để gửi product/combo mới vào giỏ
    if (itemType == 'COMBO') {
      return {
        'comboId': comboId ?? productId, // Gửi comboId
        'quantity': quantity,
        // Các trường khác của combo nếu API yêu cầu khi cập nhật/xóa
      };
    }
    return {
      'productId': productId,
      'quantity': quantity,
      'price': price, // Giá tại thời điểm thêm vào giỏ
      'note': {
        'size': size,
        'sugarLevel': sugarLevel,
        'toppings': toppings,
      },
      'toppingPrice': toppingPrice,
    };
  }
}

// Model cho toàn bộ giỏ hàng (Cart) có voucher
class Cart {
  final List<CartItem> items;
  final double totalPrice; // Đây là tổng tiền từ backend (subtotal)
  final String? voucherCode;
  final double discountAmount;
  final double finalPrice; // Giá sau khi trừ voucher

  Cart({
    required this.items,
    required this.totalPrice,
    this.voucherCode,
    this.discountAmount = 0,
    required this.finalPrice,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    // 'json' ở đây là `response.data` từ API
    // Đảm bảo rằng key lấy danh sách item là 'items' như trong response của bạn
    var itemsJson = json['items'] as List<dynamic>? ??
        []; // Đã sửa ở lần trước, kiểm tra lại
    List<CartItem> itemsList =
        itemsJson.map((item) => CartItem.fromJson(item)).toList();

    double total = (json['totalPrice'] ?? 0).toDouble();
    String? vcCode = json['voucher_code'];
    double discount = (json['discount_amount'] ?? 0).toDouble();
    double finalP = total - discount;

    return Cart(
      items: itemsList,
      totalPrice: total,
      voucherCode: vcCode,
      discountAmount: discount,
      finalPrice: finalP < 0 ? 0 : finalP,
    );
  }

  Map<String, dynamic> toJson() => {
        'products': items.map((item) => item.toJson()).toList(),
        'totalPrice': totalPrice,
        'voucher_code': voucherCode,
        'discount_amount': discountAmount,
        'finalPrice': finalPrice,
      };
}
