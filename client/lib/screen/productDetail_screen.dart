import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './../models/products.dart';
import './../config/config.dart';
import './../services/topping_service.dart';

class ProductDetail extends StatefulWidget {
  final Product product;
  final String userId;

  const ProductDetail({
    Key? key,
    required this.product,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  int quantity = 1;
  bool isAddingToCart = false;
  String selectedSize = 'M'; // Default size
  String selectedSugarLevel = '50 SG'; // Default sugar level
  List<String> selectedToppings = []; // Selected toppings
  final ToppingService _toppingService = ToppingService();
  Map<String, String> _toppingNames = {}; // Lưu trữ tên topping

  @override
  void initState() {
    super.initState();
    // Set default values from product
    if (widget.product.sizes.isNotEmpty) {
      selectedSize = widget.product.sizes.first;
    }
    if (widget.product.sugarLevels.isNotEmpty) {
      selectedSugarLevel = widget.product.sugarLevels.first;
    }
    // Tải tên topping ngay khi init
    _loadToppingNames();
  }

  Future<void> _loadToppingNames() async {
    if (widget.product.toppingIds == null ||
        widget.product.toppingIds!.isEmpty) {
      debugPrint('No toppings to load');
      return;
    }

    debugPrint('Loading toppings: ${widget.product.toppingIds}');
    final names =
        await _toppingService.getBatchToppings(widget.product.toppingIds!);

    debugPrint('Loaded toppings: $names');
    if (mounted) {
      setState(() {
        _toppingNames = names;
      });
    }
  }

  Future<void> addToCart() async {
    // Validate required fields
    if (selectedSize.isEmpty || selectedSugarLevel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn size và mức đường'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isAddingToCart = true;
    });

    try {
      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/cart/insertCart')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'productId': widget.product.id,
          'quantity': quantity,
          'size': selectedSize,
          'sugarLevel': selectedSugarLevel,
          'toppingIds': selectedToppings,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm vào giỏ hàng thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add to cart');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isAddingToCart = false;
      });
    }
  }

  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kích thước:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.product.sizes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final size = widget.product.sizes[index];
              final isSelected = selectedSize == size;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedSize = size;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.brown
                        : Colors.grey[200]!, // Thêm ! sau Colors.grey[200]
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.brown
                          : Colors.grey[300]!, // Thêm ! sau Colors.grey[300]
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      size,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSugarLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mức đường:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedSugarLevel,
          items: widget.product.sugarLevels.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedSugarLevel = value;
              });
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToppingSelector() {
    // 1. Kiểm tra null an toàn và empty
    final toppingIds = widget.product.toppingIds ?? [];
    if (toppingIds.isEmpty) {
      debugPrint('Product ID: ${widget.product.id} - No toppings available');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Topping:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Không có topping cho sản phẩm này',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // 2. Debug chi tiết
    debugPrint(
        'Displaying ${toppingIds.length} toppings for product ${widget.product.id}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Topping (+5.000đ mỗi loại):',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: toppingIds.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final toppingId = toppingIds[index];
              final isSelected = selectedToppings.contains(toppingId);

              return InputChip(
                label: Text(
                  _getToppingName(toppingId),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                selected: isSelected,
                backgroundColor:
                    isSelected ? Colors.brown : Colors.grey.shade200,
                onSelected: (selected) => setState(() {
                  selected
                      ? selectedToppings.add(toppingId)
                      : selectedToppings.remove(toppingId);
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  // Hàm giả định để lấy tên topping từ ID (thay bằng service thực tế)

  // Thay thế hàm _getToppingName bằng cách lấy từ map
  String _getToppingName(String toppingId) {
    return _toppingNames[toppingId] ?? 'Topping $toppingId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                widget.product.imageUrl,
                fit: BoxFit.cover,
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.product.price}đ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Category and Stock
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.category,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            widget.product.category,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.inventory,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Còn ${widget.product.stock}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Size Selector
                  _buildSizeSelector(),

                  const SizedBox(height: 16),

                  // Sugar Level Selector
                  _buildSugarLevelSelector(),

                  const SizedBox(height: 16),

                  // Topping Selector
                  _buildToppingSelector(),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Mô tả:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quantity Selector
                  Row(
                    children: [
                      const Text(
                        'Số lượng:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller:
                              TextEditingController(text: quantity.toString()),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final newQuantity = int.tryParse(value) ?? 1;
                              if (newQuantity >= 1 &&
                                  newQuantity <= widget.product.stock) {
                                setState(() {
                                  quantity = newQuantity;
                                });
                              } else if (newQuantity > widget.product.stock) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vượt quá số lượng tồn kho'),
                                  ),
                                );
                                setState(() {
                                  quantity = widget.product.stock;
                                });
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isAddingToCart ? null : addToCart,
                      child: isAddingToCart
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Thêm vào giỏ hàng',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
