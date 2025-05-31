import 'package:flutter/material.dart';
import 'package:myproject/models/combo_product_config_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './../models/products.dart';
import './../models/combo_model.dart';
import './productDetail_screen.dart';
import './../services/product_service.dart';
import './../services/combo_service.dart';
import './../widgets/coffee_card.dart';
import './cart_screen.dart';
import './comboDetail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String selectedCategory = 'All';
  List<Product> filteredItems = [];
  List<Product> allDisplayableItems = [];
  List<Combo> _fetchedCombos = [];
  bool isLoading = true;
  String? userId;

  final ProductService _productService = ProductService();
  final ComboService _apiService = ComboService(); // Service để gọi API combo
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
      final results = await Future.wait([
        _productService.fetchAllProducts(),
        _apiService.getAllCombos(),
      ]);

      final List<Product> regularProducts = results[0] as List<Product>;
      final List<Combo> fetchedApiCombos = results[1] as List<Combo>;

      // Lưu lại danh sách Combo gốc
      _fetchedCombos = fetchedApiCombos; // <--- LƯU LẠI

      List<Product> comboAsProducts = fetchedApiCombos.map((apiCombo) {
        // Giả sử Product.fromApiCombo gán category là 'Combo' và isCombo là true
        return Product.fromApiCombo(apiCombo);
      }).toList();

      if (!mounted) return;
      setState(() {
        allDisplayableItems = [...regularProducts, ...comboAsProducts];
        // Tùy chọn sắp xếp: đưa Combo lên đầu nếu category là 'Combo'
        allDisplayableItems.sort((a, b) {
          if (a.category == 'Combo' && b.category != 'Combo') return -1;
          if (a.category != 'Combo' && b.category == 'Combo') return 1;
          return a.name
              .compareTo(b.name); // Sắp xếp theo tên cho các mục còn lại
        });
        _applyFilterAndSearch();
        isLoading = false;
      });
    } catch (error) {
      debugPrint("Error loading all data: $error");
      if (mounted) {
        setState(() {
          isLoading = false;
          filteredItems = [];
          allDisplayableItems = [];
          _fetchedCombos = []; // Reset cả list combo gốc
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải dữ liệu: ${error.toString()}')),
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

  // void _searchProducts(String query) {
  //   _applyFilterAndSearch();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Cửa Hàng'),
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
                      // onChanged đã được xử lý bởi listener _onSearchChanged
                      // onChanged: _searchProducts,
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
                                  // _applyFilterAndSearch(); // Listener sẽ tự động gọi
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12), // Giảm padding một chút
                      itemBuilder: (context, index) {
                        final category = displayCategories[index];
                        final bool isSelected = selectedCategory == category;
                        return GestureDetector(
                          onTap: () => filterByCategory(category),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 4), // Giảm margin
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [
                                      BoxShadow(
                                        // Thêm shadow nhẹ cho nút không được chọn
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      )
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
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
                  const SizedBox(height: 10), // Thêm khoảng cách nhỏ
                  Expanded(
                    child: filteredItems.isEmpty && !isLoading
                        ? Center(
                            child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'Không tìm thấy sản phẩm nào cho danh mục "$selectedCategory"${_searchController.text.isNotEmpty ? ' với từ khóa "${_searchController.text}"' : ''}.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65, // Điều chỉnh nếu cần
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final productOrComboAdapter =
                                  filteredItems[index];

                              // --- LOGIC ĐIỀU HƯỚNG ĐẾN COMBO DETAIL ---
                              return GestureDetector(
                                onTap: () {
                                  // Kiểm tra xem item có phải là combo không
                                  // Dựa trên category hoặc trường isCombo trong model Product của bạn
                                  if (productOrComboAdapter.category == 'Combo'
                                      // Hoặc: productOrComboAdapter.isCombo == true (nếu bạn có trường này)
                                      ) {
                                    // Tìm Combo gốc từ _fetchedCombos
                                    Combo? originalCombo =
                                        _fetchedCombos.firstWhere(
                                            (c) =>
                                                c.id ==
                                                productOrComboAdapter.id,
                                            orElse: () =>
                                                null_combo_sentinel // Trả về một giá trị đặc biệt nếu không tìm thấy
                                            );

                                    if (originalCombo != null &&
                                        originalCombo != null_combo_sentinel) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ComboDetailScreen(
                                                  combo: originalCombo),
                                        ),
                                      );
                                    } else {
                                      // Xử lý trường hợp không tìm thấy Combo gốc (không nên xảy ra nếu logic đúng)
                                      debugPrint(
                                          'Original combo not found for ID: ${productOrComboAdapter.id}');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Lỗi: Không tìm thấy chi tiết combo.')),
                                      );
                                    }
                                  } else {
                                    // Nếu không phải combo, điều hướng đến ProductDetail
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetail(
                                          product: productOrComboAdapter,
                                          userId: userId ?? '',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: CoffeeCard(
                                  product: productOrComboAdapter,
                                  userId: userId ?? '',
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

  final Combo null_combo_sentinel = Combo(
    id: '__null_sentinel__',
    name: 'Invalid Combo Sentinel', // Có thể đặt tên rõ ràng hơn
    description: 'This is a sentinel value for a non-existent combo.',
    price: 0.0, // Sử dụng 0.0 cho kiểu double
    products: const <ComboProductConfigItem>[], // Danh sách rỗng với đúng kiểu
    // Hoặc: products: List<ComboProductConfig>.empty(growable: false),
    imageUrl: '', // Hoặc một URL placeholder nếu bạn có
    category: 'SENTINEL', // Cung cấp giá trị cho trường bắt buộc 'category'
    isActive: false, // Cung cấp giá trị cho trường bắt buộc 'isActive'
    createdAt: DateTime.fromMillisecondsSinceEpoch(0), // Hoặc DateTime(1970)
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0), // Hoặc DateTime(1970)
    v: 0, // Giữ nguyên hoặc có thể là null nếu v là int?
  );
}
