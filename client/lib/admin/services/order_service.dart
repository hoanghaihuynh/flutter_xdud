import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myproject/config/config.dart';
import './../models/order_model.dart';

class OrderService {
  // Lấy tất cả orders
  static Future<List<Order>> getAllOrders() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.getApiUrl('/order/getAllOrder')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Kiểm tra cấu trúc response
        if (data['data'] is List) {
          return (data['data'] as List).map((json) {
            try {
              return Order.fromJson(json);
            } catch (e) {
              print('Error parsing order: $e\nJSON: $json');
              throw Exception('Failed to parse order data');
            }
          }).toList();
        } else {
          throw Exception('Invalid data format: expected array');
        }
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllOrders: $e');
      throw Exception('OrderService - getAllOrders error: $e');
    }
  }

  // Xóa order
  static Future<bool> deleteOrder(String orderId) async {
    try {
      final response = await http.delete(
        Uri.parse(AppConfig.getApiUrl('/order/deleteOrder/$orderId')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('Order not found');
      } else {
        throw Exception('Failed to delete order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('OrderService - deleteOrder error: $e');
    }
  }
}
