// services/table_service.dart

import 'dart:convert'; // Để sử dụng jsonEncode và jsonDecode
import 'package:http/http.dart' as http; // Import thư viện http
import 'package:myproject/config/config.dart';
import './../models/table.dart';

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
          'Content-Type': 'application/json; charset=UTF-8',
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

  // CALL API InsertTable
  Future<TableModel> insertTable({
    required String tableNumber,
    required int capacity,
    required String description,
    required String status,
  }) async {
    final Uri uri = Uri.parse(AppConfig.getApiUrl('/table/insertTable'));
    print('TableService: Calling POST $uri');

    // Chuẩn bị dữ liệu body cho request
    final Map<String, dynamic> requestBody = {
      'table_number': tableNumber,
      'capacity': capacity,
      'description': description,
      'status': status,
    };

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody), // Mã hóa body thành chuỗi JSON
      );

      // In ra response để debug (bạn có thể xóa hoặc comment lại sau)
      print(
          'TableService: InsertTable Response Status: ${response.statusCode}');
      print('TableService: InsertTable Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Thường POST thành công trả về 201 (Created) hoặc 200
        // API trả về đối tượng JSON chứa thông tin bàn mới
        final Map<String, dynamic> responseData =
            jsonDecode(utf8.decode(response.bodyBytes));

        // Kiểm tra xem response có chứa key "newTable" không
        if (responseData.containsKey('newTable') &&
            responseData['newTable'] != null) {
          // Lấy object "newTable" từ response
          final Map<String, dynamic> newTableJson =
              responseData['newTable'] as Map<String, dynamic>;
          return TableModel.fromJson(newTableJson);
        } else {
          // Nếu response không đúng định dạng mong đợi
          print(
              'TableService: Lỗi - Response JSON không chứa "newTable" hoặc "newTable" là null.');
          throw Exception(
              'Failed to insert table: Invalid response format from server.');
        }
      } else {
        // Xử lý các lỗi HTTP khác
        print(
            'TableService: Failed to insert table. Status code: ${response.statusCode}');
        print('TableService: Response body: ${response.body}');
        // Cố gắng parse lỗi từ server nếu có
        String errorMessage =
            'Failed to insert table (Status code: ${response.statusCode})';
        try {
          final Map<String, dynamic> errorData =
              jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData.containsKey('message')) {
            // Giả sử server trả về lỗi trong trường 'message'
            errorMessage += ': ${errorData['message']}';
          } else {
            errorMessage += '. Response: ${response.body}';
          }
        } catch (e) {
          // Không parse được lỗi JSON, dùng response.body
          errorMessage += '. Response: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Xử lý lỗi mạng hoặc lỗi parse JSON
      print('TableService: Error inserting table: $e');
      throw Exception('Error inserting table: $e');
    }
  }

  // Lấy DS bàn còn trống
  Future<List<TableModel>> getAvailableTables() async {
    final Uri url = Uri.parse(AppConfig.getApiUrl('/table/getAllTables'));

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-T_8',
        },
      );

      if (response.statusCode == 200) {
        // API trả về danh sách JSON, giải mã nó
        final List<dynamic> decodedJson =
            json.decode(utf8.decode(response.bodyBytes));
        // Chuyển đổi danh sách dynamic thành danh sách TableModel
        List<TableModel> tables = decodedJson
            .map((jsonItem) => TableModel.fromJson(jsonItem))
            .toList();
        // Lọc chỉ lấy những bàn 'available' (nếu API chưa tự lọc)
        // Nếu API đã trả về đúng danh sách bàn 'available' thì dòng filter này không cần thiết.
        // List<TableModel> availableTables = tables.where((table) => table.status == 'available').toList();
        // return availableTables;
        return tables; // Trả về toàn bộ danh sách nếu API đã tự lọc
      } else {
        // Xử lý các trường hợp lỗi khác (ví dụ: 404, 500)
        // Bạn có thể throw một Exception cụ thể hơn để UI có thể xử lý.
        throw Exception(
            'Failed to load tables. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      // Xử lý lỗi kết nối hoặc các lỗi khác trong quá trình gọi API
      // Bạn có thể log lỗi hoặc throw một Exception tùy chỉnh.
      print('Error fetching available tables: $e');
      throw Exception('Error fetching available tables: $e');
    }
  }

  // Xóa bàn
  Future<Map<String, dynamic>> deleteTable(String tableId) async {
    final Uri uri =
        Uri.parse(AppConfig.getApiUrl('/table/deleteTable/$tableId'));
    print('TableService: Calling DELETE $uri');

    try {
      final response = await http.delete(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          // Thêm các headers cần thiết khác, ví dụ: Authorization token nếu API yêu cầu
          // 'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
        },
      );

      // In ra response để debug
      print(
          'TableService: DeleteTable Response Status: ${response.statusCode}');
      print('TableService: DeleteTable Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // API của bạn trả về 200 khi thành công
        // API trả về một đối tượng JSON chứa message và data (bàn đã xóa)
        final Map<String, dynamic> responseData =
            jsonDecode(utf8.decode(response.bodyBytes));
        return responseData; // Trả về toàn bộ response data để UI có thể dùng message hoặc data
      } else {
        // Xử lý các lỗi HTTP khác
        print(
            'TableService: Failed to delete table. Status code: ${response.statusCode}');
        print('TableService: Response body: ${response.body}');
        String errorMessage =
            'Failed to delete table (Status code: ${response.statusCode})';
        try {
          final Map<String, dynamic> errorData =
              jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData.containsKey('message')) {
            errorMessage += ': ${errorData['message']}';
          } else {
            errorMessage += '. Response: ${response.body}';
          }
        } catch (e) {
          errorMessage += '. Response: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Xử lý lỗi mạng hoặc lỗi parse JSON
      print('TableService: Error deleting table: $e');
      throw Exception('Error deleting table: $e');
    }
  }
}
