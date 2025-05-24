import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myproject/config/config.dart';
import './../models/topping_model.dart';

class ToppingService {
  // Lấy tất cả toppings
  Future<List<Topping>> getAllToppings() async {
    final response = await http.get(
        Uri.parse(AppConfig.getApiUrl('/topping/getAllToppings')),
        headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Topping.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load toppings: ${response.statusCode}');
    }
  }

  // Lấy topping theo ID
  Future<Topping> getToppingById(String id) async {
    final response = await http.get(
        Uri.parse(AppConfig.getApiUrl('/topping/getToppingById/$id')),
        headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      return Topping.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load topping: ${response.statusCode}');
    }
  }

  // Thêm topping mới
  Future<Topping> createTopping(Topping topping) async {
    final response = await http.post(
      Uri.parse(AppConfig.getApiUrl('/topping/insertTopping')),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(topping.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Topping.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create topping: ${response.statusCode}');
    }
  }

  // Cập nhật topping
  Future<Topping> updateTopping(
      String id, Map<String, dynamic> updateData) async {
    final response = await http.put(
      Uri.parse(AppConfig.getApiUrl('/topping/updateTopping/$id')),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      return Topping.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update topping: ${response.statusCode}');
    }
  }

  // Xóa topping
  Future<void> deleteTopping(String id) async {
    final response = await http.delete(
      Uri.parse(AppConfig.getApiUrl('/topping/deleteTopping/$id')),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete topping: ${response.statusCode}');
    }
  }
}
