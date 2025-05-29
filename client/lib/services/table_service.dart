// services/table_service.dart

import 'dart:convert'; // Để sử dụng jsonEncode và jsonDecode
import 'package:http/http.dart' as http; // Import thư viện http
import 'package:myproject/config/config.dart';
import './../models/table.dart'; // Đường dẫn tới file table_model.dart của bạn

class TableService {
  // Lấy tất cả các bàn
  Future<List<TableModel>> getAllTables() async {
    final Uri uri = Uri.parse(AppConfig.getApiUrl('/table/getAllTables'));
    print('TableService: Calling GET $uri');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        // Chuyển đổi từng item JSON trong danh sách thành TableModel
        return jsonData.map((jsonItem) {
          print(
              'TableService: Đang xử lý jsonItem: $jsonItem'); // Dòng log bạn đã thêm
          if (jsonItem is Map<String, dynamic>) {
            try {
              return TableModel.fromJson(jsonItem);
            } catch (e) {
              print(
                  'TableService: LỖI khi parse jsonItem: $jsonItem - Lỗi: $e'); // Dòng này sẽ in ra item lỗi
              throw e;
            }
          } else {
            // Nếu một item không phải là Map, log và throw lỗi
            print(
                'TableService: Lỗi - jsonItem không phải là Map<String, dynamic>. Kiểu thực tế: ${jsonItem.runtimeType}, Giá trị: $jsonItem');
            throw FormatException(
                'Dữ liệu JSON không hợp lệ: một item không phải là Map.');
          }
        }).toList(); // Câu lệnh return cho trường hợp thành công (statusCode == 200)
      } else {
        // Xử lý các lỗi HTTP khác và throw Exception
        print(
            'TableService: Failed to load tables. Status code: ${response.statusCode}');
        print('TableService: Response body: ${response.body}');
        throw Exception(
            'Failed to load tables (Status code: ${response.statusCode})'); // Câu lệnh throw cho trường hợp lỗi HTTP
      }
    } catch (e) {
      // Xử lý lỗi mạng hoặc lỗi parse JSON và throw Exception
      print('TableService: Error fetching tables: $e');
      throw Exception(
          'Error fetching tables: $e'); // Câu lệnh throw cho trường hợp có exception trong try block
    }
    // **QUAN TRỌNG**: Không nên có bất kỳ code nào ở đây, vì tất cả các nhánh
    // trong try-catch đều đã return hoặc throw. Nếu hàm có thể chạy đến đây,
    // nó sẽ ngầm trả về null và gây ra lỗi bạn đang gặp.
  }

  // CALL API UpdateTable
  Future<TableModel> updateTable(
      String tableId, Map<String, dynamic> updateData) async {
    final Uri uri =
        Uri.parse(AppConfig.getApiUrl('/table/updateTable/$tableId'));
    // print(
    //     'TableService: Update table $uri with data: $updateData'); // Log URL và data

    try {
      final response = await http.put(
        uri,
        headers: <String, String>{
          'Content-Type':
              'application/json; charset=UTF-LOWERCASE_U_T_F8', // Sửa thành 'application/json; charset=UTF-8'
        },
        body: jsonEncode(updateData), // Chuyển đổi Map thành chuỗi JSON
      );

      if (response.statusCode == 200) {
        // API trả về đối tượng bàn đã được cập nhật
        final dynamic jsonData = jsonDecode(response.body);
        return TableModel.fromJson(jsonData);
      } else {
        // Xử lý các lỗi HTTP khác
        print(
            'TableService: Failed to update table. Status code: ${response.statusCode}');
        print('TableService: Response body: ${response.body}');
        throw Exception(
            'Failed to update table (Status code: ${response.statusCode})');
      }
    } catch (e) {
      // Xử lý lỗi mạng hoặc lỗi parse JSON
      print('TableService: Error updating table: $e');
      throw Exception('Error updating table: $e');
    }
  }
}
