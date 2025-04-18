import 'package:flutter/material.dart';
import 'package:myproject/models/carts.dart';
// import 'package:myproject/models/products.dart';
// import 'package:myproject/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myproject/utils/getUserId.dart';
// import 'package:intl/intl.dart';

class CartService {
  static const String _baseUrl = 'http://192.168.1.5:3000/cart';

  // Call api thêm vào giỏ hàng
  static Future<void> addToCart({
    required String userId,
    required String productId,
    required BuildContext context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/insertCart'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {"userId": userId, "productId": productId, "quantity": 1}),
      );

      final scaffoldMessenger = ScaffoldMessenger.of(context);

      if (response.statusCode == 201) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('ĐÃ THÊM VÀO GIỎ HÀNG'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final responseData = jsonDecode(response.body);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Call api fetch giỏ hàng theo user id
  static Future<List<CartItem>> fetchCartByUserId(String userId) async {
    final url = Uri.parse('$_baseUrl/getCartByUserId/$userId');
    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['data'] == null ||
          responseData['data']['products'] == null) {
        return [];
      }

      final cartData = responseData['data']['products'] as List;

      return cartData.map((item) {
        try {
          return CartItem.fromJson(item);
        } catch (e) {
          print('Error parsing item: $e');
          return CartItem(
            id: item['_id'] ?? 'unknown',
            productId: item['productId']['_id'] ?? 'unknown_product',
            name: item['productId']['name'] ?? 'Unknown Product',
            price: (item['price'] ?? 0).toDouble(),
            quantity: item['quantity'] ?? 1,
            imageUrl: item['productId']['imageUrl'] ??
                'https://via.placeholder.com/150',
          );
        }
      }).toList();
    } else {
      throw Exception('Failed to load cart: ${response.statusCode}');
    }
  }

  // Call api xóa item khỏi giỏ hàng
  static Future<Map<String, dynamic>> removeItem({
    required String userId,
    required String cartItemId,
    required String productId,
  }) async {
    final url = Uri.parse('$_baseUrl/removeProduct/');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'cartItemId': cartItemId,
        'productId': productId,
      }),
    );

    final responseData = json.decode(response.body);
    return {
      'statusCode': response.statusCode,
      'body': responseData,
    };
  }

  // Call api edit lượng items
  static Future<Map<String, dynamic>> updateQuantity({
    required String userId,
    required String productId,
    required int newQuantity,
  }) async {
    final url = Uri.parse('$_baseUrl/updateCartQuantity');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'productId': productId,
        'newQuantity': newQuantity,
      }),
    );

    final responseData = json.decode(response.body);
    return {
      'statusCode': response.statusCode,
      'body': responseData,
    };
  }
  
}
