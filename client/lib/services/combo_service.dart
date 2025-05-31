import 'package:http/http.dart' as http;
import 'package:myproject/config/config.dart';
import 'package:myproject/models/inserted_combo_data.dart';
import 'dart:convert';
import '../models/combo_model.dart';

class ComboService {
  // Hàm lấy tất cả combo
  Future<List<Combo>> getAllCombos() async {
    // Endpoint đã được cung cấp: http://localhost:3000/combo/getAllCombo
    // AppConfig.getApiUrl('/combo/getAllCombo') sẽ tạo ra URL này
    final String url = AppConfig.getApiUrl('/combo/getAllCombo');
    print('Fetching combos from: $url'); // Log URL để kiểm tra

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      try {
        // response.body là chuỗi JSON nhận được từ API
        // Hàm parseCombos (định nghĩa ở trên hoặc trong combo_model.dart) sẽ xử lý nó
        return parseCombos(response.body);
      } catch (e) {
        // Lỗi xảy ra trong quá trình parse (ví dụ: trong Combo.fromJson hoặc ComboProductConfig.fromJson)
        print('Error parsing combos in getAllCombos service: $e');
        print('Response body was: ${response.body}');
        // Ném lại lỗi để lớp gọi có thể xử lý (ví dụ: hiển thị thông báo lỗi trên UI)
        throw Exception('Không thể xử lý dữ liệu combo nhận được: $e');
      }
    } else {
      // Lỗi từ server (ví dụ: 404 Not Found, 500 Internal Server Error)
      print(
          'Failed to load combos. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception(
          'Không thể tải danh sách combo (Mã lỗi: ${response.statusCode})');
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
    final Uri uri =
        Uri.parse(AppConfig.getApiUrl('/combo/updateCombo/$comboId'));

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

      if (response.statusCode == 200) {
        // API update thường trả về 200 OK
        // Response body giống với insertCombo, nên có thể dùng cùng hàm parse
        return parseInsertedComboData(
            response.body); // Hoặc parseInsertedComboData(response.body)
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

  // Delete combo
  Future<DeleteResponseMessage> deleteCombo({
    required String comboId,
    String? authToken, // Token xác thực (tùy chọn)
  }) async {
    final Uri uri =
        Uri.parse(AppConfig.getApiUrl('/combo/deleteCombo/$comboId'));

    final Map<String, String> headers = {
      'Content-Type':
          'application/json; charset=UTF-8', // Vẫn nên có dù không có body
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    try {
      final response = await http.delete(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        // API delete thành công thường trả về 200 OK (nếu có body) hoặc 204 No Content
        // Dựa trên response bạn cung cấp, nó có body message nên 200 OK là hợp lý
        return parseDeleteResponseMessage(response.body);
      } else if (response.statusCode == 204) {
        // Nếu API trả về 204, không có body để parse.
        // Bạn có thể trả về một đối tượng DeleteResponseMessage mặc định.
        return DeleteResponseMessage(
            message: 'Combo deleted successfully (204)');
      } else {
        // Xử lý các lỗi khác từ server
        String errorMessage =
            'Failed to delete combo (Status Code: ${response.statusCode})';
        try {
          // Thử parse body lỗi nếu có
          final errorBody = json.decode(response.body);
          if (errorBody['message'] != null) {
            errorMessage =
                'Failed to delete combo: ${errorBody['message']} (Status Code: ${response.statusCode})';
          }
        } catch (_) {
          // Nếu body không phải JSON hoặc không có message, dùng body gốc (nếu ngắn)
          if (response.body.isNotEmpty && response.body.length < 200) {
            errorMessage += ' - Body: ${response.body}';
          }
        }
        print(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Xử lý lỗi mạng hoặc các lỗi khác
      print('Error during deleteCombo API call: $e');
      throw Exception('Error deleting combo: $e');
    }
  }
}
