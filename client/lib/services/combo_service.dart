import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:myproject/config/config.dart';
import 'package:myproject/models/inserted_combo_data.dart';
import 'dart:convert';
import '../models/combo_model.dart';
import '../models/combo_product_config_item.dart';

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
  required List<ComboProductConfigItem> productsConfig,
  // required String imageUrl, // Bỏ tham số này nếu chỉ dùng upload file
  double? price, // Sửa lại kiểu cho price nếu cần
  File? imageFile, // << THÊM THAM SỐ FILE
  String? authToken,
}) async {
  final Uri uri = Uri.parse(AppConfig.getApiUrl('/combo/insertCombo'));
  var request = http.MultipartRequest('POST', uri);

  // Thêm các trường text
  request.fields['name'] = name;
  request.fields['description'] = description;
  if (price != null) { // Kiểm tra null cho price
      request.fields['price'] = price.toString();
  } else {
      request.fields['price'] = '0'; // Hoặc giá trị mặc định/xử lý lỗi
  }

  // Thêm mảng productsConfig (cần encode đúng cách cho multipart)
  for (int i = 0; i < productsConfig.length; i++) {
    request.fields['products[$i][productId]'] = productsConfig[i].productId;
    request.fields['products[$i][quantityInCombo]'] = productsConfig[i].quantityInCombo.toString();
    request.fields['products[$i][defaultSize]'] = productsConfig[i].defaultSize;
    request.fields['products[$i][defaultSugarLevel]'] = productsConfig[i].defaultSugarLevel;
    // Gửi defaultToppings nếu có
    for (int j = 0; j < productsConfig[i].defaultToppings.length; j++) {
        request.fields['products[$i][defaultToppings][$j]'] = productsConfig[i].defaultToppings[j];
    }
  }
  
  // Thêm file ảnh nếu có
  if (imageFile != null) {
    request.files.add(await http.MultipartFile.fromPath(
      'comboImage', // Tên trường này phải khớp với backend multer config
      imageFile.path,
      // contentType: MediaType('image', 'jpeg'), // Tùy chọn: chỉ định content type
    ));
  } else {
    // Nếu không có file mới và bạn cho phép nhập URL (đã bỏ ở ví dụ này)
    // request.fields['imageUrl'] = imageUrl; // Gửi URL dạng text
    // Hoặc không gửi gì cả nếu backend có ảnh mặc định
  }

  if (authToken != null && authToken.isNotEmpty) {
    request.headers['Authorization'] = 'Bearer $authToken';
  }
  // Không cần 'Content-Type': 'application/json' nữa vì đây là multipart

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return parseInsertedComboData(response.body);
    } else {
      print('Failed to insert combo. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception(
          'Failed to insert combo (Status Code: ${response.statusCode}) - Body: ${response.body}');
    }
  } catch (e) {
    print('Error during insertCombo API call: $e');
    throw Exception('Error inserting combo: $e');
  }
}

  // Update combo
  Future<InsertedComboData> updateCombo({
  required String comboId,
  required String name,
  required String description,
  required List<ComboProductConfigItem> productsConfig,
  // required String imageUrl, // Sẽ được xử lý bởi imageFile hoặc currentImageUrl
  required double price,
  File? imageFile, // File ảnh mới (có thể null nếu không thay đổi ảnh)
  String? currentImageUrl, // URL của ảnh hiện tại (nếu không có imageFile mới và muốn giữ ảnh cũ)
  String? authToken,
}) async {
  final Uri uri = Uri.parse(AppConfig.getApiUrl('/combo/updateCombo/$comboId'));
  var request = http.MultipartRequest('PUT', uri); // Sử dụng PUT cho update

  // Thêm các trường text vào request.fields
  request.fields['name'] = name;
  request.fields['description'] = description;
  request.fields['price'] = price.toString();

  // Thêm mảng productsConfig
  for (int i = 0; i < productsConfig.length; i++) {
    request.fields['products[$i][productId]'] = productsConfig[i].productId;
    request.fields['products[$i][quantityInCombo]'] = productsConfig[i].quantityInCombo.toString();
    request.fields['products[$i][defaultSize]'] = productsConfig[i].defaultSize;
    request.fields['products[$i][defaultSugarLevel]'] = productsConfig[i].defaultSugarLevel;
    for (int j = 0; j < productsConfig[i].defaultToppings.length; j++) {
      request.fields['products[$i][defaultToppings][$j]'] = productsConfig[i].defaultToppings[j];
    }
  }

  // Xử lý ảnh
  if (imageFile != null) {
    // Nếu có file ảnh mới được chọn để upload
    request.files.add(await http.MultipartFile.fromPath(
      'comboImage', // Tên trường này phải khớp với backend multer config
      imageFile.path,
    ));
    // Khi có file mới, backend sẽ xử lý và tạo imageUrl mới.
    // Bạn không cần gửi currentImageUrl trong trường hợp này.
    // Backend có thể tự xóa ảnh cũ nếu cần.
  } else if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
    // Nếu không có file ảnh mới VÀ người dùng muốn giữ lại/chỉ định URL ảnh hiện tại
    // (Backend sẽ nhận trường này nếu không có req.file)
    request.fields['imageUrl'] = currentImageUrl;
  }
  // Nếu cả imageFile và currentImageUrl đều null/rỗng,
  // backend có thể giữ nguyên ảnh cũ của combo hoặc xóa ảnh nếu logic được thiết kế như vậy.
  // Hoặc bạn có thể thêm một trường boolean ví dụ 'removeCurrentImage': true nếu muốn xóa ảnh mà không thay thế.

  // Thêm headers
  if (authToken != null && authToken.isNotEmpty) {
    request.headers['Authorization'] = 'Bearer $authToken';
  }
  // http.MultipartRequest sẽ tự đặt Content-Type phù hợp.

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) { // API update thường trả về 200 OK
      return parseInsertedComboData(response.body);
    } else {
      print('Failed to update combo. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      // Thử parse lỗi JSON nếu có
      String errorMessage = 'Failed to update combo (Status Code: ${response.statusCode})';
      try {
        final errorData = json.decode(response.body);
        if (errorData['error'] is String) {
          errorMessage = errorData['error'];
        } else if (errorData['message'] is String) {
           errorMessage = errorData['message'];
        } else if (response.body.isNotEmpty) {
            errorMessage += ' - Body: ${response.body}';
        }
      } catch (e) {
          if (response.body.isNotEmpty) {
            errorMessage += ' - Body: ${response.body}';
          }
      }
      throw Exception(errorMessage);
    }
  } catch (e) {
    print('Error during updateCombo API call: $e');
    throw Exception('Error updating combo: ${e.toString()}');
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
