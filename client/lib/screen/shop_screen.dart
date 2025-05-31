import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './../models/products.dart';
import './../models/combo_model.dart';
import './productDetail_screen.dart';
import './../services/product_service.dart';
import './../services/combo_service.dart';
import './../widgets/coffee_card.dart';
import './cart_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String selectedCategory = 'All';
  List<Product> filteredItems = [];
  List<Product> allDisplayableItems = []; // Sẽ chứa cả Product thường và Combo (đã adapt)
  bool isLoading = true;
  String? userId;

  final ProductService _productService = ProductService();
  final ApiService _apiService = ApiService(); // Service để gọi API combo
  final TextEditingController _searchController = TextEditingController();

  // Danh sách categories (có thể lấy từ productCategories trong models/products.dart nếu bạn muốn)
  static const List<String> displayCategories = [
    'All',
    'Combo',
    'Coffee',
    'Tea',
    'Smoothies',
    'Pastries',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchData(); // Gộp lại để đảm bảo userId có trước khi fetch nếu cần
  }

  Future<void> _loadUserIdAndFetchData() async {
    await _loadUserId(); // Chờ userId load xong
    await _fetchAllData(); // Sau đó fetch data
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        userId = prefs.getString('userId');
      });
    } catch (e) {
      debugPrint('Error getting userId: $e');
      // Xử lý lỗi nếu cần thiết, ví dụ hiển thị thông báo
    }
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      // Gọi API lấy sản phẩm thường và API lấy combo đồng thời
      final results = await Future.wait([
        _productService.fetchAllProducts(), // Trả về List<Product>
        _apiService.getAllCombos(),       // Trả về List<Combo> (tên class Combo theo file combo_model.dart)
      ]);

      final List<Product> regularProducts = results[0] as List<Product>;
      final List<Combo> fetchedApiCombos = results[1] as List<Combo>; // Sử dụng class Combo từ model

      // Chuyển đổi List<Combo> (từ API) thành List<Product> (model hiển thị)
      List<Product> comboAsProducts = fetchedApiCombos.map((apiCombo) {
        // Sử dụng factory Product.fromApiCombo đã định nghĩa trong models/products.dart
        return Product.fromApiCombo(apiCombo);
      }).toList();

      if (!mounted) return;
      setState(() {
        allDisplayableItems = [...regularProducts, ...comboAsProducts];
        // Sắp xếp (tùy chọn, ví dụ theo tên hoặc để combo lên đầu)
        // allDisplayableItems.sort((a, b) {
        //   if (a.isCombo && !b.isCombo) return -1;
        //   if (!a.isCombo && b.isCombo) return 1;
        //   return a.name.compareTo(b.name);
        // });
        _applyFilterAndSearch(); // Áp dụng filter và search hiện tại
        isLoading = false;
      });
    } catch (error) {
      debugPrint("Error loading all data: $error");
      if (mounted) {
        setState(() {
          isLoading = false;
          // filteredItems và allDisplayableItems có thể rỗng để UI hiển thị "Không có sản phẩm"
          filteredItems = [];
          allDisplayableItems = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${error.toString()}')),
        );
      }
    }
  }

  void _applyFilterAndSearch() {
    if (!mounted) return;
    String query = _searchController.text.toLowerCase();
    List<Product> tempFilteredItems;

    // 1. Lọc theo category
    if (selectedCategory == 'All') {
      tempFilteredItems = List.from(allDisplayableItems);
    } else {
      tempFilteredItems = allDisplayableItems
          .where((item) => item.category == selectedCategory)
          .toList();
    }

    // 2. Lọc theo search query trên kết quả đã lọc theo category
    if (query.isNotEmpty) {
      tempFilteredItems = tempFilteredItems.where((product) {
        final name = product.name.toLowerCase();
        return name.contains(query);
      }).toList();
    }
    setState(() {
      filteredItems = tempFilteredItems;
    });
  }

  void filterByCategory(String category) {
    if (!mounted) return;
    setState(() {
      selectedCategory = category;
    });
    _applyFilterAndSearch();
  }

  void _searchProducts(String query) {
    // Việc gọi _applyFilterAndSearch đã được thực hiện trong filterByCategory
    // và sẽ được gọi mỗi khi text thay đổi.
    // Nếu bạn muốn search hoạt động độc lập với category filter khi query thay đổi,
    // thì gọi _applyFilterAndSearch ở đây.
    // Hiện tại, hàm này đang được gọi bởi onChanged của TextField,
    // nên nó sẽ tự động cập nhật filteredItems dựa trên query MỚI NHẤT và selectedCategory HIỆN TẠI.
    _applyFilterAndSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Cửa Hàng'), // Đổi title nếu muốn
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
          : RefreshIndicator(
              onRefresh: _fetchAllData,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _searchProducts, // Sẽ gọi _applyFilterAndSearch
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm sản phẩm, combo...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchProducts(''); // Gọi để cập nhật lại list
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: displayCategories.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final category = displayCategories[index];
                        return GestureDetector(
                          onTap: () => filterByCategory(category),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8), // Thêm vertical padding
                            decoration: BoxDecoration(
                              color: selectedCategory == category
                                  ? Theme.of(context).primaryColor // Sử dụng màu chủ đạo
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: selectedCategory == category
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300),
                              boxShadow: selectedCategory == category
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: selectedCategory == category
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: selectedCategory == category
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredItems.isEmpty && !isLoading
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'Không tìm thấy sản phẩm nào cho danh mục "$selectedCategory"${_searchController.text.isNotEmpty ? ' với từ khóa "${_searchController.text}"' : ''}.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65, // Bạn có thể cần điều chỉnh tỷ lệ này
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final productOrCombo = filteredItems[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetail(
                                        // ProductDetail cần được cập nhật để xử lý isCombo
                                        // và hiển thị detailedComboItems nếu là combo
                                        product: productOrCombo,
                                        userId: userId ?? '',
                                      ),
                                    ),
                                  );
                                },
                                child: CoffeeCard(
                                  product: productOrCombo,
                                  userId: userId ?? '',
                                  // CoffeeCard cũng có thể cần cập nhật để hiển thị
                                  // dấu hiệu "Combo" nếu productOrCombo.isCombo là true
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
