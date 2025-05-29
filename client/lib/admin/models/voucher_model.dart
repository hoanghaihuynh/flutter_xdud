class Voucher {
  final String id;
  final String code;
  final String discountType; // 'percent' or 'fixed'
  final double discountValue;
  final double maxDiscount;
  final DateTime startDate;
  final DateTime expiryDate;
  final int quantity;
  final int usedCount;
  final int version;

  Voucher({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscount,
    required this.startDate,
    required this.expiryDate,
    required this.quantity,
    required this.usedCount,
    required this.version,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['_id'] as String,
      code: json['code'] as String,
      discountType: json['discount_type'] as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      maxDiscount: (json['max_discount'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      quantity: json['quantity'] as int,
      usedCount: json['used_count'] as int,
      version: json['__v'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'code': code,
        'discount_type': discountType,
        'discount_value': discountValue,
        'max_discount': maxDiscount,
        'start_date': startDate.toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'quantity': quantity,
        'used_count': usedCount,
        '__v': version,
      };

  // Kiểm tra voucher còn hiệu lực không
  bool get isValid {
    final now = DateTime.now();
    return now.isAfter(startDate) && 
           now.isBefore(expiryDate) && 
           (usedCount < quantity);
  }

  // Tính toán giá trị giảm giá thực tế
  double calculateDiscount(double totalAmount) {
    if (!isValid) return 0;

    if (discountType == 'fixed') {
      return discountValue;
    } else {
      // Kiểu phần trăm
      final discount = totalAmount * discountValue / 100;
      return maxDiscount > 0 ? discount.clamp(0, maxDiscount) : discount;
    }
  }
}