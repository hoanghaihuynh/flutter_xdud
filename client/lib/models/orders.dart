// models/order.dart
import './payment.dart';

class Order {
  final String id;
  final User user; // Giữ nguyên User model nếu backend populate user_id
  final List<OrderItem>
      items; // <<--- THAY ĐỔI: từ List<OrderProduct> sang List<OrderItem>
  final double total;
  final double subtotal; // <<--- THÊM MỚI
  final double discountAmount; // <<--- THÊM MỚI
  final String? voucherCode; // <<--- THÊM MỚI (nếu chưa có)
  final String status;
  final DateTime createdAt;
  final String? paymentMethod;
  final PaymentInfo? paymentInfo;
  final String? tableId;
  final String? tableNumber;

  Order({
    required this.id,
    required this.user,
    required this.items, // <<--- THAY ĐỔI
    required this.total,
    required this.subtotal, // <<--- THÊM MỚI
    required this.discountAmount, // <<--- THÊM MỚI
    this.voucherCode, // <<--- THÊM MỚI
    required this.status,
    required this.createdAt,
    this.paymentMethod,
    this.paymentInfo,
    this.tableId,
    this.tableNumber,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var userIdData = json['user_id'];
    User parsedUser;
    if (userIdData is Map<String, dynamic>) {
      parsedUser = User.fromJson(userIdData);
    } else if (userIdData is String) {
      parsedUser = User(id: userIdData, email: 'N/A'); // Hoặc email rỗng
    } else {
      // Gán giá trị mặc định nếu user_id không hợp lệ hoặc null
      parsedUser = User(id: '', email: 'Unknown User');
    }

    return Order(
      id: json['_id'] as String,
      user: parsedUser,
      items: (json['items'] as List<dynamic>?)
              ?.map((x) => OrderItem.fromJson(x as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] as num).toDouble(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      voucherCode: json['voucher_code'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      paymentMethod: json['payment_method'] as String?,
      paymentInfo: json['paymentInfo'] != null
          ? PaymentInfo.fromJson(json['paymentInfo'] as Map<String, dynamic>)
          : null,
      tableId: json['table_id'] as String?,
      tableNumber: json['table_number'] as String?,
    );
  }
}

class User {
  final String id;
  final String email;
  // final String? name; // Nếu backend populate thêm name
  // final String? avatar; // Nếu backend populate thêm avatar

  User({required this.id, required this.email /*, this.name, this.avatar*/});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      email: json['email'] as String? ??
          'N/A', // Để email không bị null nếu API không trả về
      // name: json['name'] as String?,
      // avatar: json['avatar'] as String?,
    );
  }
}

class OrderItem {
  final String id;
  final String itemType;
  final String? productId; // Sẽ lưu _id của sản phẩm
  final String? comboId; // Sẽ lưu _id của combo
  final String name;
  final String? imageUrl;
  final int quantity;
  final double price;
  final OrderItemNote note;
  final double toppingPrice;

  OrderItem({
    required this.id,
    required this.itemType,
    this.productId,
    this.comboId,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.price,
    required this.note,
    required this.toppingPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    String? parsedProductId;
    String? parsedComboId;

    // Xử lý product_id (có thể là String hoặc Map do populate)
    var prodIdData = json['product_id'];
    if (prodIdData is String) {
      parsedProductId = prodIdData;
    } else if (prodIdData is Map<String, dynamic>) {
      parsedProductId = prodIdData['_id'] as String?;
    }

    // Xử lý combo_id (có thể là String hoặc Map do populate)
    var comboIdData = json['combo_id'];
    if (comboIdData is String) {
      parsedComboId = comboIdData;
    } else if (comboIdData is Map<String, dynamic>) {
      parsedComboId = comboIdData['_id'] as String?;
    }

    return OrderItem(
      id: json['_id'] as String? ?? '',
      itemType: json['itemType'] as String? ?? 'PRODUCT',
      productId: parsedProductId,
      comboId: parsedComboId,
      name: json['name'] as String? ?? 'Unknown Item',
      imageUrl: json['imageUrl'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      note: OrderItemNote.fromJson(json['note'] as Map<String, dynamic>? ?? {}),
      toppingPrice: (json['toppingPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
  Map<String, dynamic> toJson() => {
        '_id': id,
        'itemType': itemType,
        'product_id': productId,
        'combo_id': comboId,
        'name': name,
        'imageUrl': imageUrl,
        'quantity': quantity,
        'price': price,
        'note': note.toJson(),
        'toppingPrice': toppingPrice,
      };
}

class OrderNote {
  final String size;
  final String sugarLevel;
  final List<String> toppings;
  final double toppingPrice;

  OrderNote({
    required this.size,
    required this.sugarLevel,
    required this.toppings,
    required this.toppingPrice,
  });

  factory OrderNote.fromJson(Map<String, dynamic> json) {
    return OrderNote(
      size: json['size'] ?? 'M', // Giá trị mặc định nếu null
      sugarLevel: json['sugarLevel'] ?? '50%', // Giá trị mặc định
      toppings: List<String>.from(json['toppings'] ?? []),
      toppingPrice: (json['toppingPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'size': size,
        'sugarLevel': sugarLevel,
        'toppings': toppings,
        'toppingPrice': toppingPrice,
      };
}

class Product {
  final String id;
  final String name;
  final double price;
  final String? imageUrl; // Thêm trường ảnh

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
      };
}

class OrderTopping {
  final String name;
  final double price;

  OrderTopping({required this.name, required this.price});

  factory OrderTopping.fromJson(Map<String, dynamic> json) {
    return OrderTopping(
      name: json['name'] ?? 'Unknown Topping',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
      };
}

class ComboProductSnapshotItem {
  final String productId;
  final String name;
  final int quantityInCombo;
  final String? defaultSize;
  final String? defaultSugarLevel;
  // final List<String> defaultToppings; // Tùy nếu backend gửi và bạn cần

  ComboProductSnapshotItem({
    required this.productId,
    required this.name,
    required this.quantityInCombo,
    this.defaultSize,
    this.defaultSugarLevel,
  });

  factory ComboProductSnapshotItem.fromJson(Map<String, dynamic> json) {
    return ComboProductSnapshotItem(
      productId: json['productId'] ?? '',
      name: json['name'] ?? 'Unknown Product',
      quantityInCombo: (json['quantityInCombo'] as num?)?.toInt() ?? 1,
      defaultSize: json['defaultSize'] as String?,
      defaultSugarLevel: json['defaultSugarLevel'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'quantityInCombo': quantityInCombo,
        'defaultSize': defaultSize,
        'defaultSugarLevel': defaultSugarLevel,
      };
}

class OrderItemNote {
  final String? size;
  final String? sugarLevel;
  final List<OrderTopping> toppings;
  final List<ComboProductSnapshotItem>? comboProductsSnapshot;

  OrderItemNote({
    this.size,
    this.sugarLevel,
    required this.toppings,
    this.comboProductsSnapshot,
  });

  factory OrderItemNote.fromJson(Map<String, dynamic> json) {
    return OrderItemNote(
      size: json['size'] as String?,
      sugarLevel: json['sugarLevel'] as String?,
      toppings: (json['toppings'] as List<dynamic>?)
              ?.map((x) => OrderTopping.fromJson(x as Map<String, dynamic>))
              .toList() ??
          [],
      comboProductsSnapshot: (json['comboProductsSnapshot'] as List<dynamic>?)
          ?.map((x) =>
              ComboProductSnapshotItem.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => {
        'size': size,
        'sugarLevel': sugarLevel,
        'toppings': toppings.map((t) => t.toJson()).toList(),
        'comboProductsSnapshot':
            comboProductsSnapshot?.map((cs) => cs.toJson()).toList(),
      };
}
