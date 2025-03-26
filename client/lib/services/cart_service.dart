import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const String _baseUrl = "http://192.168.1.5:3000";

  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<bool> addToCart(String productId, int quantity) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return false;

      final url = Uri.parse('$_baseUrl/cart/addToCart');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'productId': productId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to add to cart: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }
}