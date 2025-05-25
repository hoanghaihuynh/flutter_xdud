import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myproject/config/config.dart';
import './../models/cart_model.dart';

class CartService {
  static const Duration _timeout = Duration(seconds: 10);

  // Lấy tất cả carts với thông tin sản phẩm đầy đủ
  static Future<List<Cart>> getAllCarts() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.getApiUrl('/cart/getAllCart')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List).map((json) => Cart.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load carts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('CartService - getAllCarts error: $e');
    }
  }

  // Lấy cart theo userId
  static Future<Cart> getCartByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.getApiUrl('/cart/getCartByUserId/$userId')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Cart.fromJson(data['data']);
      } else {
        throw Exception('Failed to load cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('CartService - getCartByUserId error: $e');
    }
  }

  // Tìm kiếm carts theo userId
  static Future<List<Cart>> searchCarts(String query) async {
    try {
      final allCarts = await getAllCarts();
      return allCarts.where((cart) => 
        cart.userId.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      throw Exception('CartService - searchCarts error: $e');
    }
  }
}