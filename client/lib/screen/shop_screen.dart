import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './../models/products.dart';
import './productDetail_screen.dart';
import './../services/product_service.dart';
import './../widgets/coffee_card.dart';
import './cart_screen.dart';

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
  String? userId;
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

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
      final products = await _productService.fetchAllProducts();
      setState(() {
        allProducts = products;
        filteredItems = List.from(allProducts);
        isLoading = false;
      });
    } catch (error) {
      print("Error loading products: $error");
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

  // Chức năng tìm kiếm sản phẩm
  void _searchProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredItems = selectedCategory == 'All'
            ? List.from(allProducts)
            : allProducts
                .where((item) => item.category == selectedCategory)
                .toList();
      } else {
        filteredItems = allProducts.where((product) {
          final name = product.name.toLowerCase();
          final searchLower = query.toLowerCase();
          final categoryMatch =
              selectedCategory == 'All' || product.category == selectedCategory;
          return name.contains(searchLower) && categoryMatch;
        }).toList();
      }
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
                    controller: _searchController,
                    onChanged: _searchProducts,
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
