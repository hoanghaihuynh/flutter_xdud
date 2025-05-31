import 'package:http/http.dart' as http;
import 'package:myproject/config/config.dart';
import 'package:myproject/models/inserted_combo_data.dart';
import 'dart:convert';
import '../models/combo_model.dart';

class ApiService {
  // Hàm lấy tất cả combo
  Future<List<Combo>> getAllCombos() async {
    final response = await http.get(
      Uri.parse(AppConfig.getApiUrl(
          '/combo/getAllCombo')), // Ghép endpoint vào base URL
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      try {
        return parseCombos(response.body);
      } catch (e) {
        print('Error parsing combos: $e');
        throw Exception('Failed to parse combos: $e');
      }
    } else {
      // Nếu server không trả về response OK,
      // thì ném ra một exception.
      // print('Failed to load combos. Status code: ${response.statusCode}');
      // print('Response body: ${response.body}');
      throw Exception(
          'Failed to load combos (Status Code: ${response.statusCode})');
    }
  }

  // Thêm combo
  Future<InsertedComboData> insertCombo({
    required String name,
    required String description,
    required List<String>
        productIds, // Danh sách ID của các sản phẩm trong combo
    required String imageUrl,
    required double price,
    String? authToken, // Token xác thực (tùy chọn)
  }) async {
    final Uri uri = Uri.parse(AppConfig.getApiUrl('/combo/insertCombo'));

    // Chuẩn bị request body
    final Map<String, dynamic> requestBody = {
      'name': name,
      'description': description,
      'products': productIds,
      'imageUrl': imageUrl,
      'price': price,
    };

    // Chuẩn bị headers
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody), // Encode request body thành JSON string
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // API thường trả về 201 Created cho POST thành công, nhưng 200 OK cũng có thể xảy ra
        // Dựa trên response bạn cung cấp, có vẻ như nó trả về dữ liệu của combo vừa tạo.
        return parseInsertedComboData(response.body);
      } else {
        // Xử lý các lỗi khác từ server
        print('Failed to insert combo. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        // Bạn có thể parse response.body nếu server trả về lỗi dạng JSON
        // final errorResponse = json.decode(response.body);
        // throw Exception('Failed to insert combo: ${errorResponse['message'] ?? response.reasonPhrase}');
        throw Exception(
            'Failed to insert combo (Status Code: ${response.statusCode}) - Body: ${response.body}');
      }
    } catch (e) {
      // Xử lý lỗi mạng hoặc các lỗi khác trong quá trình gọi API
      print('Error during insertCombo API call: $e');
      throw Exception('Error inserting combo: $e');
    }
  }

  // Update combo
  Future<InsertedComboData> updateCombo({
    required String comboId, // ID của combo cần cập nhật
    required String name,
    required String description,
    required List<String> productIds,
    required String imageUrl,
    required double price,
    String? authToken, // Token xác thực (tùy chọn)
  }) async {
    // Xây dựng URL với path parameter
    final Uri uri = Uri.parse(AppConfig.getApiUrl('/combo/updateCombo/$comboId'));

    final Map<String, dynamic> requestBody = {
      'name': name,
      'description': description,
      'products': productIds,
      'imageUrl': imageUrl,
      'price': price,
    };

    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    try {
      // Sử dụng http.put cho việc cập nhật
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) { // API update thường trả về 200 OK
        // Response body giống với insertCombo, nên có thể dùng cùng hàm parse
        return parseInsertedComboData(response.body); // Hoặc parseInsertedComboData(response.body)
      } else {
        print('Failed to update combo. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'Failed to update combo (Status Code: ${response.statusCode}) - Body: ${response.body}');
      }
    } catch (e) {
      print('Error during updateCombo API call: $e');
      throw Exception('Error updating combo: $e');
    }
  }
}
