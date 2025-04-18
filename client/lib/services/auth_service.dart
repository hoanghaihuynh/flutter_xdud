import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myproject/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  static Future<Map<String, dynamic>> registerUser(
      String email, String password) async {
    final registerUrl = Uri.parse(AppConfig.getApiUrl('/registration'));

    try {
      final response = await http.post(
        registerUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData["message"] ?? "ĐĂNG KÝ THÀNH CÔNG!",
        };
      } else {
        return {
          'success': false,
          'message': responseData["message"] ?? "Đăng ký thất bại!",
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': "Lỗi kết nối đến server!",
      };
    }
  }

  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final loginUrl = Uri.parse(AppConfig.getApiUrl('/login'));

    final response = await http.post(
      loginUrl,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final responseData = jsonDecode(response.body);

    if (responseData['status'] == 200) {
      final prefs = await SharedPreferences.getInstance();
      final token = responseData['token'];
      prefs.setString('token', token);

      final decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['_id'];
      prefs.setString('userId', userId);

      return {
        'success': true,
        'message': responseData['message'],
        'token': token,
        'userId': userId,
      };
    } else {
      return {
        'success': false,
        'message': responseData['error'] ?? 'Đăng nhập thất bại!',
      };
    }
  }
}
