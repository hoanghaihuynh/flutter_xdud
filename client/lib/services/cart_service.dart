import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import './../models/carts.dart'; // Đổi từ carts.dart sang cart_item.dart
import './../config/config.dart';

class CartService {
  // Thêm sản phẩm vào giỏ hàng với đầy đủ thông tin
  static Future<bool> addToCart({
    required String userId,
    required String productId,
    required String size,
    required String sugarLevel,
    required List<String> toppingIds,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/cart/insertCart')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'size': size,
          'sugarLevel': sugarLevel,
          'toppingIds': toppingIds,
        }),
      );

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('ĐÃ THÊM VÀO GIỎ HÀNG'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? 'Có lỗi khi thêm vào giỏ hàng'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Lấy giỏ hàng theo userId
  static Future<List<CartItem>> fetchCartByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.getApiUrl('/cart/getCartByUserId/$userId')),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final products = responseData['data']?['items'] as List? ?? [];

        return products.map((item) {
          return CartItem.fromJson(item);
        }).toList();
      } else {
        throw Exception('Failed to load cart. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
      rethrow;
    }
  }

  // Xóa sản phẩm khỏi giỏ hàng
  static Future<Map<String, dynamic>> removeItem({
    required String userId,
    required String cartItemId,
    required String productId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(AppConfig.getApiUrl('/cart/removeProduct')),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userId': userId,
              'cartItemId': cartItemId,
              'productId': productId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);
      return {
        'statusCode': response.statusCode,
        'body': responseData,
      };
    } catch (e) {
      debugPrint('Error removing item: $e');
      return {
        'statusCode': 500,
        'body': {'error': e.toString()},
      };
    }
  }

  // Cập nhật số lượng sản phẩm
  static Future<Map<String, dynamic>> updateQuantity({
    required String userId,
    required String productId,
    required int newQuantity,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(AppConfig.getApiUrl('/cart/updateCartQuantity')),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userId': userId,
              'productId': productId,
              'newQuantity': newQuantity,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);
      return {
        'statusCode': response.statusCode,
        'body': responseData,
      };
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      return {
        'statusCode': 500,
        'body': {'error': e.toString()},
      };
    }
  }

  // Lấy tổng giá giỏ hàng (tuỳ chọn)
  static Future<double> getCartTotal(String userId) async {
    try {
      final cartItems = await fetchCartByUserId(userId);
      double total = 0;
      for (final item in cartItems) {
        total += item.totalPrice;
      }
      return total;
    } catch (e) {
      debugPrint('Error calculating cart total: $e');
      return 0;
    }
  }
}
