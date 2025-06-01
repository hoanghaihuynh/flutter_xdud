import 'package:flutter/material.dart';
import '../models/combo_model.dart';
import '../services/cart_service.dart';
import '../models/products.dart';
import '../services/product_service.dart';
import '../utils/getUserId.dart';

// class CartService {
//   Future<void> addComboToCart(Combo combo, int quantity) async {
//     // Logic thêm combo vào giỏ hàng của bạn
//     print('Adding combo ${combo.name} (Quantity: $quantity) to cart (Mock).');
//     // Đây là nơi bạn sẽ gọi API hoặc cập nhật state quản lý giỏ hàng
//     await Future.delayed(const Duration(seconds: 1)); // Giả lập network call
//   }
// }

class ComboDetailScreen extends StatefulWidget {
  final Combo combo;

  const ComboDetailScreen({Key? key, required this.combo}) : super(key: key);

  @override
  State<ComboDetailScreen> createState() => _ComboDetailScreenState();
}

class _ComboDetailScreenState extends State<ComboDetailScreen> {
  int quantity = 1;
  bool isAddingToCart = false;
  late TextEditingController _quantityController;
  final CartService _cartService = CartService(); // Khởi tạo CartService (Mock)
  List<Product> _availableProducts = []; // Danh sách tất cả sản phẩm thường
  bool _isLoadingProducts = true; // Trạng thái tải danh sách sản phẩm
  final ProductService _productService = ProductService();
  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: quantity.toString());
    _fetchAvailableProducts(); // Gọi hàm fetch sản phẩm
  }

  Future<void> _fetchAvailableProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProducts = true;
    });
    try {
      final products = await _productService
          .fetchAllProducts(); // Gọi service lấy tất cả sản phẩm
      if (!mounted) return;
      setState(() {
        _availableProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách sản phẩm: $e')),
      );
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity >= 1) {
      // Bạn có thể thêm logic kiểm tra stock tối đa của combo ở đây nếu cần
      // Ví dụ: if (newQuantity > widget.combo.availableStock) return;
      setState(() {
        quantity = newQuantity;
        _quantityController.text = quantity.toString();
        _quantityController.selection = TextSelection.fromPosition(
            TextPosition(offset: _quantityController.text.length));
      });
    }
  }

  Product? _getProductDetails(String productId) {
    try {
      return _availableProducts.firstWhere((p) => p.id == productId);
    } catch (e) {
      // Không tìm thấy sản phẩm, có thể trả về null hoặc một Product placeholder
      print('Không tìm thấy chi tiết sản phẩm cho ID: $productId');
      return null;
    }
  }

  void addToCart() async {
    if (_isLoadingProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Đang tải thông tin sản phẩm, vui lòng thử lại sau.')),
      );
      return;
    }

    // Client-side stock check (sơ bộ)
    bool productInComboOutOfStock = false;
    for (var comboConfigItem in widget.combo.products) {
      final productDetail = _getProductDetails(comboConfigItem.productId);
      if (productDetail == null ||
          productDetail.stock < comboConfigItem.quantityInCombo) {
        productInComboOutOfStock = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Sản phẩm "${productDetail?.name ?? comboConfigItem.productId}" trong combo không đủ hàng.')),
        );
        break;
      }
    }

    if (productInComboOutOfStock) {
      return;
    }

    if (quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số lượng hợp lệ.')),
      );
      return;
    }

    setState(() {
      isAddingToCart = true;
    });

    final userId = await getUserId();
    if (!mounted) return; // Kiểm tra mounted sau await

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng!'),
            backgroundColor: Colors.orange),
      );
      setState(() {
        isAddingToCart = false;
      });
      return;
    }

    try {
      // Gọi CartService thật trực tiếp qua tên lớp do là phương thức static
      bool success = await CartService.addComboToCart(
        // << THAY ĐỔI Ở ĐÂY
        userId: userId,
        comboId: widget.combo.id, // Giả sử widget.combo.id là ID của combo
        quantity: quantity,
        context: context, // Truyền context để CartService hiển thị SnackBar
      );

      if (mounted && success) {
        // CartService đã hiển thị SnackBar thành công.
        print('${widget.combo.name} (x$quantity) đã được thêm vào giỏ hàng!');
      }
      // Trường hợp lỗi, CartService cũng đã hiển thị SnackBar lỗi.
    } catch (e) {
      if (mounted) {
        print('Lỗi không xác định khi thêm vào giỏ hàng: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool anyProductOutOfStock = false;
    if (!_isLoadingProducts) {
      anyProductOutOfStock = widget.combo.products.any((comboConfigItem) {
        final productDetail = _getProductDetails(comboConfigItem.productId);
        return productDetail == null ||
            productDetail.stock < comboConfigItem.quantityInCombo;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.combo.name),
        centerTitle: true,
      ),
      body: _isLoadingProducts
          ? const Center(
              child: CircularProgressIndicator(
                  semanticsLabel: 'Đang tải dữ liệu sản phẩm...'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: Hero(
                      tag: 'combo_image_${widget.combo.id}', //
                      child: Image.network(
                        widget.combo.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image,
                                size: 100, color: Colors.grey[400]),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.combo.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${widget.combo.price.toStringAsFixed(0)}đ',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (widget.combo.description.isNotEmpty) ...[
                          Text(
                            'Mô tả combo:',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.combo.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Bao gồm các sản phẩm:',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (widget.combo.products.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Combo này hiện không có sản phẩm nào được liệt kê.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.combo.products.length,
                            itemBuilder: (context, index) {
                              final comboConfigItem =
                                  widget.combo.products[index];
                              final productDetail =
                                  _getProductDetails(comboConfigItem.productId);

                              if (productDetail == null) {
                                return Card(
                                  elevation: 1,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  child: ListTile(
                                    leading: const Icon(Icons.error_outline,
                                        color: Colors.red, size: 40),
                                    title: const Text('Sản phẩm lỗi',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    subtitle: Text(
                                        'ID: ${comboConfigItem.productId} (Không tìm thấy thông tin)'),
                                  ),
                                );
                              }

                              bool productOutOfStock = productDetail.stock <
                                  comboConfigItem.quantityInCombo;

                              return Card(
                                elevation: 1,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(4.0),
                                    child: Image.network(
                                      productDetail.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: Icon(Icons.fastfood,
                                              color: Colors.grey[400]),
                                        );
                                      },
                                    ),
                                  ),
                                  title: Text(
                                      '${productDetail.name} (x${comboConfigItem.quantityInCombo})',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${productDetail.price.toStringAsFixed(0)}đ / sản phẩm'),
                                      Text(
                                          'Size: ${comboConfigItem.defaultSize}, Đường: ${comboConfigItem.defaultSugarLevel}'),
                                      if (comboConfigItem
                                          .defaultToppings.isNotEmpty)
                                        Text(
                                            'Topping: ${comboConfigItem.defaultToppings.join(", ")}'),
                                      if (productOutOfStock)
                                        Text(
                                            "- Hết hàng cho cấu hình combo này",
                                            style: TextStyle(
                                                color: Colors.red.shade700)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số lượng combo:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: Colors.brown,
                                  disabledColor: Colors.grey,
                                  onPressed: isAddingToCart || quantity <= 1
                                      ? null
                                      : () => _updateQuantity(quantity - 1),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: TextField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    enabled: !isAddingToCart,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.grey),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.brown, width: 1.5),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (isAddingToCart) return;
                                      if (value.isNotEmpty) {
                                        final newQuantity = int.tryParse(value);
                                        if (newQuantity != null) {
                                          _updateQuantity(newQuantity);
                                        }
                                      }
                                    },
                                    onSubmitted: (value) {
                                      if (isAddingToCart) return;
                                      if (value.isEmpty ||
                                          (int.tryParse(value) ?? 0) < 1) {
                                        _updateQuantity(1);
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: Colors.brown,
                                  disabledColor: Colors.grey,
                                  onPressed: isAddingToCart
                                      ? null
                                      : () => _updateQuantity(quantity + 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor:
                                  Colors.brown.withOpacity(0.5),
                            ),
                            onPressed: isAddingToCart ||
                                    quantity < 1 ||
                                    (_isLoadingProducts
                                        ? true
                                        : anyProductOutOfStock)
                                ? null
                                : addToCart, //
                            child: isAddingToCart //
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 3),
                                  )
                                : Text('Thêm vào giỏ hàng',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        )),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
