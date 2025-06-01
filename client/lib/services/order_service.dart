import 'dart:convert';
import 'package:http/http.dart' as http;
import './../config/config.dart';
import './../models/orders.dart';

class OrderService {
  Future<List<Order>> getOrdersByUserId(String userId) async {
    final response = await http.get(
      Uri.parse(AppConfig.getApiUrl('/order/getAllOrder?user_id=$userId')),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData =
          json.decode(response.body); // Đổi tên biến data thành responseData
      if (responseData['status'] == 200 && responseData['data'] != null) {
        // Kiểm tra data có null không
        // Dữ liệu đơn hàng nằm trong responseData['data']
        List<dynamic> ordersJson = responseData['data'];
        return ordersJson
            .map((x) => Order.fromJson(x as Map<String, dynamic>))
            .toList();
      } else {
        // Nếu không có đơn hàng hoặc có lỗi từ API message
        if (responseData['data'] == null ||
            (responseData['data'] as List).isEmpty) {
          return []; // Trả về danh sách rỗng nếu không có đơn hàng
        }
        throw Exception(responseData['message'] ?? 'Failed to parse orders');
      }
    } else {
      throw Exception(
          'Failed to load orders. Status code: ${response.statusCode}');
    }
  }
}
