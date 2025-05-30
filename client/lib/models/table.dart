class TableModel {
  final String id; // Sẽ là _id từ MongoDB
  final String tableNumber;
  final int capacity;
  final String status;
  final String? description; // Có thể null
  final DateTime createdAt;
  final DateTime updatedAt;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.status,
    this.description, // Tham số tùy chọn
    required this.createdAt,
    required this.updatedAt,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    String _parseString(Map<String, dynamic> data, String key) {
      final value = data[key];
      if (value is String) return value;
      if (value == null)
        throw FormatException(
            "Lỗi parse JSON cho TableModel: Trường '$key' là null, nhưng được yêu cầu là String. Dữ liệu JSON đang parse: $data");
      throw FormatException(
          "Lỗi parse JSON cho TableModel: Trường '$key' không phải là String (kiểu dữ liệu hiện tại: ${value.runtimeType}). Dữ liệu JSON đang parse: $data");
    }

    // Hàm trợ giúp để lấy DateTime an toàn
    DateTime _parseDateTime(Map<String, dynamic> data, String key) {
      final value = data[key];
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          throw FormatException(
              "Lỗi parse JSON cho TableModel: Không thể parse trường '$key' ('$value') thành DateTime. Lỗi gốc: $e. Dữ liệu JSON đang parse: $data");
        }
      }
      if (value == null)
        throw FormatException(
            "Lỗi parse JSON cho TableModel: Trường '$key' (dùng cho DateTime) là null. Dữ liệu JSON đang parse: $data");
      throw FormatException(
          "Lỗi parse JSON cho TableModel: Trường '$key' (dùng cho DateTime) không phải là String (kiểu dữ liệu hiện tại: ${value.runtimeType}). Dữ liệu JSON đang parse: $data");
    }

    // Hàm trợ giúp để lấy int an toàn
    int _parseInt(Map<String, dynamic> data, String key) {
      final value = data[key];
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsedInt = int.tryParse(value);
        if (parsedInt != null) return parsedInt;
        throw FormatException(
            "Lỗi parse JSON cho TableModel: Trường '$key' ('$value') không thể chuyển thành int. Dữ liệu JSON đang parse: $data");
      }
      if (value == null)
        throw FormatException(
            "Lỗi parse JSON cho TableModel: Trường '$key' là null, nhưng được yêu cầu là int. Dữ liệu JSON đang parse: $data");
      throw FormatException(
          "Lỗi parse JSON cho TableModel: Trường '$key' không phải là số (kiểu dữ liệu hiện tại: ${value.runtimeType}). Dữ liệu JSON đang parse: $data");
    }

    try {
      return TableModel(
        id: _parseString(json, '_id'),
        tableNumber: _parseString(
            json, 'table_number'), // Giữ nguyên snake_case nếu API trả về vậy
        capacity: _parseInt(
            json, 'capacity'), // Giữ nguyên snake_case nếu API trả về vậy
        status: _parseString(
            json, 'status'), // Giữ nguyên snake_case nếu API trả về vậy
        description: json['description'] as String?,
        // SỬA Ở ĐÂY:
        createdAt: _parseDateTime(
            json, 'createdAt'), // Đổi thành 'createdAt' (camelCase)
        updatedAt: _parseDateTime(
            json, 'updatedAt'), // Đổi thành 'updatedAt' (camelCase)
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'table_number': tableNumber,
      'capacity': capacity,
      'status': status,
    };
    // Chỉ thêm description vào JSON nếu nó không null
    if (description != null) {
      data['description'] = description;
    }
    return data;
  }
}
