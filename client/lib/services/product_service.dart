import 'dart:convert';
import 'package:http/http.dart' as http;
import './../models/products.dart';
import './../config/config.dart';

class ProductService {
  Future<List<Products>> fetchAllProducts() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.getApiUrl('/products/getAll')),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        List<dynamic> productsJson = data['products'];
        return productsJson.map((json) => Products.fromJson(json)).toList();
      } else {
        throw Exception(
            "Failed to load products. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching products: $error");
      throw Exception("Failed to fetch products: $error");
    }
  }
}
