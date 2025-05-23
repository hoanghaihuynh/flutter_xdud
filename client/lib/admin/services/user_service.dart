import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myproject/config/config.dart';
import '../models/user_model.dart';

class UserService {
  // Lấy tất cả users
  Future<List<User>> getAllUsers() async {
    final response = await http.get(
      Uri.parse(AppConfig.getApiUrl('/users/getAll')),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      //print('data: $data'); ok
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  // Lấy user theo ID
  Future<User> getUserById(String id) async {
    final response = await http.get(
      Uri.parse(AppConfig.getApiUrl('/users/getUserById/$id')),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body)['data']);
    } else {
      throw Exception('Failed to load user: ${response.statusCode}');
    }
  }

  // Cập nhật thông tin user
  Future<User> updateProfile(String userId,
      {String? email, String? role}) async {
    final response = await http.put(
      Uri.parse(AppConfig.getApiUrl('/updateProfile/$userId')),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        if (email != null) 'email': email,
        if (role != null) 'role': role,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body)['data']);
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }
}
