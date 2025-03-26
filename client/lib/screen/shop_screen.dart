import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myproject/models/products.dart';
import 'package:myproject/utils/constants.dart';
import 'package:myproject/widgets/coffee_card.dart';
import 'package:myproject/screen/cart_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String selectedCategory = 'All';
  List<Products> filteredItems = [];
  List<Products> allProducts = []; // Danh sách sản phẩm từ API
  bool isLoading = true; // Trạng thái loading

  @override
  void initState() {
    super.initState();
    fetchProducts(); // Gọi API khi màn hình được load
  }

  Future<void> fetchProducts() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.1.5:3000/products/getAll'));
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
              // Điều hướng đến giỏ hàng
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Hiển thị loading khi gọi API
          : Column(
              children: [
                // Thanh tìm kiếm
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

                // Danh mục sản phẩm
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

                // Grid sản phẩm
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return CoffeeCard(coffee: filteredItems[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
