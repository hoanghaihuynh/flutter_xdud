import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myproject/config/config.dart';
import './../models/product_model.dart';

class ProductService {
  Future<List<Product>> getAllProducts() async {
    final response =
        await http.get(Uri.parse(AppConfig.getApiUrl('/products/getAll')));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);

      // Sửa từ 'data' thành 'products' theo API thực tế
      if (responseData['products'] != null) {
        final List<dynamic> products = responseData['products'];
        return products.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  Future<Product> getProductById(String id) async {
    final response = await http
        .get(Uri.parse(AppConfig.getApiUrl('/products/getProductByID/$id')));

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body)['data']);
    } else {
      throw Exception('Failed to load product: ${response.statusCode}');
    }
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse(AppConfig.getApiUrl('/products/insertProduct')),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(productData),
    );

    if (response.statusCode == 201) {
      return Product.fromJson(json.decode(response.body)['data']);
    } else {
      throw Exception('Failed to create product: ${response.statusCode}');
    }
  }

  Future<Product> updateProduct(
      String productId, Map<String, dynamic> updateData) async {
    final response = await http.put(
      Uri.parse(AppConfig.getApiUrl('/products/updateProduct/$productId')),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body)['data']);
    } else {
      throw Exception('Failed to update product: ${response.statusCode}');
    }
  }

  Future<void> deleteProduct(String id) async {
    final response = await http
        .delete(Uri.parse(AppConfig.getApiUrl('/products/deleteProduct/$id')));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.statusCode}');
    }
  }
}
