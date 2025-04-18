import './../config/config.dart';
import './../models/orders.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderService {
  Future<List<Order>> getOrdersByUserId(String userId) async {
    final response = await http.get(
      Uri.parse(AppConfig.getApiUrl('/order/getAllOrder?user_id=$userId')),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 200) {
        return List<Order>.from(data['data'].map((x) => Order.fromJson(x)));
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load orders');
    }
  }
}
