import 'dart:convert';
import 'package:http/http.dart' as http;
import './../models/products.dart';
import './../config/config.dart';

class ProductService {
  Future<List<Product>> fetchAllProducts() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.getApiUrl('/products/getAll')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Xử lý cả 2 trường hợp response trả về:
        // 1. Danh sách products trực tiếp
        // 2. Object có thuộc tính 'products'
        List<dynamic> productsJson =
            data is List ? data : data['products'] ?? [];

        return productsJson.map<Product>((json) {
          try {
            return Product.fromJson(json);
          } catch (e) {
            print('Error parsing product: $e\nJSON: $json');
            throw Exception('Invalid product data format');
          }
        }).toList();
      } else {
        throw Exception(
            "Failed to load products. Status code: ${response.statusCode}. Body: ${response.body}");
      }
    } catch (error) {
      print("Error fetching products: $error");
      throw Exception("Failed to fetch products: ${error.toString()}");
    }
  }

  // fetch product detail
  static Future<Product> fetchProductDetail(String productId) async {
    final response = await http.get(
      Uri.parse(AppConfig.getApiUrl('/products/getProductByID/$productId')),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return Product.fromJson(responseData['data'] ?? responseData);
    } else {
      throw Exception('Failed to load product detail');
    }
  }
}
