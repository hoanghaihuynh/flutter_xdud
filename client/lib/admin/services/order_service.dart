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

      print('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['data'] is List) {
          return (data['data'] as List).map((json) {
            try {
              final orderMap = json is String ? jsonDecode(json) : json;
              return Order.fromJson(orderMap);
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

  // Hàm updateOrder
  static Future<Order?> updateOrder({
    required String orderId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      final url = Uri.parse(AppConfig.getApiUrl('/order/updateOrder'));
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        'orderId': orderId,
        'updateData': updateData,
      });

      final response = await http.put(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('response : $responseData');
        return Order.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to update order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update order: ${e.toString()}');
    }
  }
}
