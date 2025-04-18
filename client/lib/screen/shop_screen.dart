import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myproject/models/products.dart';
import 'package:myproject/screen/productDetail_screen.dart';
import 'package:myproject/utils/constants.dart';
import 'package:myproject/widgets/coffee_card.dart';
import 'package:myproject/screen/cart_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String selectedCategory = 'All';
  List<Products> filteredItems = [];
  List<Products> allProducts = [];
  bool isLoading = true;
  String? userId; // Thêm biến lưu trữ userId

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Tải userId khi khởi tạo
    fetchProducts();
  }

  // Hàm tải userId từ SharedPreferences
  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userId = prefs.getString('userId');
      });
    } catch (e) {
      print('Error getting userId: $e');
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http
          .get(Uri.parse('http://172.20.12.120:3000/products/getAll'));
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        List<dynamic> productsJson = data['products'];

        setState(() {
          allProducts =
              productsJson.map((json) => Products.fromJson(json)).toList();
          filteredItems = List.from(allProducts);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load products");
      }
    } catch (error) {
      print("Error fetching products: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterByCategory(String category) {
    setState(() {
      selectedCategory = category;
      filteredItems = category == 'All'
          ? List.from(allProducts)
          : allProducts.where((item) => item.category == category).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Shop'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return GestureDetector(
                        onTap: () => filterByCategory(category),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: selectedCategory == category
                                ? Colors.black
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: selectedCategory == category
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetail(
                                product: filteredItems[index],
                                userId: userId ?? '',
                              ),
                            ),
                          );
                        },
                        child: CoffeeCard(
                          coffee: filteredItems[index],
                          userId: userId ?? '',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
