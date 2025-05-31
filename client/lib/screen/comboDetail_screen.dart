import 'package:flutter/material.dart';
import '../models/combo_model.dart';
// import '../services/cart_service.dart';
import '../models/products.dart';
import '../services/product_service.dart';

class CartService {
  Future<void> addComboToCart(Combo combo, int quantity) async {
    // Logic thêm combo vào giỏ hàng của bạn
    print('Adding combo ${combo.name} (Quantity: $quantity) to cart (Mock).');
    // Đây là nơi bạn sẽ gọi API hoặc cập nhật state quản lý giỏ hàng
    await Future.delayed(const Duration(seconds: 1)); // Giả lập network call
  }
}

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
      // Chờ sản phẩm tải xong
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Đang tải thông tin sản phẩm, vui lòng thử lại sau.')),
      );
      return;
    }
    bool productInComboOutOfStock = false;
    for (var comboConfigItem in widget.combo.products) {
      final productDetail = _getProductDetails(comboConfigItem.productId);
      if (productDetail == null ||
          productDetail.stock < comboConfigItem.quantityInCombo) {
        // Nếu sản phẩm không tìm thấy hoặc không đủ stock (quantityInCombo là số lượng trong 1 combo)
        // Ở đây, chúng ta kiểm tra stock của sản phẩm con so với số lượng của nó TRONG MỘT COMBO.
        // Nếu bạn muốn kiểm tra stock so với (số lượng trong 1 combo * tổng số combo muốn mua (biến `quantity`)),
        // thì điều kiện sẽ là: productDetail.stock < (comboConfigItem.quantityInCombo * quantity)
        // Tuy nhiên, việc kiểm tra stock tổng khi nhấn nút "Thêm vào giỏ hàng" thường do API backend đảm nhiệm
        // để đảm bảo tính nhất quán. Kiểm tra ở client chỉ mang tính sơ bộ.
        // Trong trường hợp này, chỉ cần kiểm tra sản phẩm đó có còn hàng không (stock > 0) là đủ ở client.
        // Backend sẽ kiểm tra kỹ hơn khi thực sự thêm vào giỏ.
        // Vì vậy, đơn giản hóa: kiểm tra xem sản phẩm có stock > 0 không.
        // Hoặc, nếu bạn muốn kiểm tra chính xác hơn cho 1 combo:
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
    }

    if (productInComboOutOfStock) {
      // ScaffoldMessenger.of(context).showSnackBar( // Đã show ở trên
      //   const SnackBar(content: Text('Một hoặc nhiều sản phẩm trong combo này đã hết hàng.')),
      // );
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

    try {
      await _cartService.addComboToCart(widget.combo, quantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${widget.combo.name} (x$quantity) đã được thêm vào giỏ hàng!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm vào giỏ hàng: $e')),
        );
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
    // Kiểm tra nếu có sản phẩm nào trong combo hết hàng để vô hiệu hóa nút thêm
    bool anyProductOutOfStock = false;
    if (!_isLoadingProducts) {
      // Chỉ kiểm tra khi đã tải xong sản phẩm
      anyProductOutOfStock = widget.combo.products.any((comboConfigItem) {
        final productDetail = _getProductDetails(comboConfigItem.productId);
        // Một sản phẩm được coi là hết hàng NẾU nó không tìm thấy HOẶC stock của nó < số lượng cần cho 1 combo
        // Để đơn giản cho nút "Thêm vào giỏ hàng", chỉ cần sản phẩm đó có stock > 0 là được.
        // Việc backend từ chối vì không đủ số lượng cho `quantity` combo sẽ được xử lý sau.
        // Hoặc, nếu bạn muốn nút bị disable nếu không đủ cho ÍT NHẤT 1 combo:
        return productDetail == null ||
            productDetail.stock < comboConfigItem.quantityInCombo;
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.combo.name),
        centerTitle: true,
      ),
      body:
          _isLoadingProducts // Thêm trạng thái loading cho toàn bộ body nếu cần
              ? const Center(
                  child: CircularProgressIndicator(
                      semanticsLabel: 'Đang tải dữ liệu sản phẩm...'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ... (Phần Ảnh combo, Tên combo, Giá combo, Mô tả giữ nguyên) ...
                      AspectRatio(
                        // Image
                        aspectRatio: 1.2,
                        child: Hero(
                          tag: 'combo_image_${widget.combo.id}',
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

                      // Combo Details
                      Padding(
                        // Details
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              // Name and Price
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

                            // Description
                            if (widget.combo.description.isNotEmpty) ...[
                              // Description
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

                            // Products in Combo
                            Text(
                              'Bao gồm các sản phẩm:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (widget.combo.products.isEmpty)
                              // ... ( giữ nguyên ) ...
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
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
                                  // Lấy thông tin chi tiết của sản phẩm từ _availableProducts
                                  final productDetail = _getProductDetails(
                                      comboConfigItem.productId);

                                  if (productDetail == null) {
                                    // Trường hợp không tìm thấy sản phẩm (có thể do lỗi dữ liệu hoặc chưa tải xong)
                                    return Card(
                                      elevation: 1,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6.0),
                                      child: ListTile(
                                        leading: Icon(Icons.error_outline,
                                            color: Colors.red, size: 40),
                                        title: Text('Sản phẩm lỗi',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500)),
                                        subtitle: Text(
                                            'ID: ${comboConfigItem.productId} (Không tìm thấy thông tin)'),
                                      ),
                                    );
                                  }

                                  // Bây giờ productDetail là một đối tượng Product đầy đủ
                                  bool productOutOfStock = productDetail.stock <
                                      comboConfigItem
                                          .quantityInCombo; // Kiểm tra với số lượng trong 1 combo

                                  return Card(
                                    elevation: 1,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 6.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      leading: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                        child: Image.network(
                                          productDetail
                                              .imageUrl, // << SỬ DỤNG imageUrl từ productDetail
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              /* ... placeholder ... */
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
                                          '${productDetail.name} (x${comboConfigItem.quantityInCombo})', // << SỬ DỤNG name từ productDetail, hiển thị số lượng trong combo
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500)),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${productDetail.price.toStringAsFixed(0)}đ / sản phẩm'), // Giá của một sản phẩm lẻ
                                          Text(
                                              'Size: ${comboConfigItem.defaultSize}, Đường: ${comboConfigItem.defaultSugarLevel}'),
                                          if (comboConfigItem
                                              .defaultToppings.isNotEmpty)
                                            Text(
                                                'Topping: ${comboConfigItem.defaultToppings.join(", ")}'), // Giả sử defaultToppings là List<String> tên topping
                                          if (productOutOfStock)
                                            Text(
                                                "- Hết hàng cho cấu hình combo này",
                                                style: TextStyle(
                                                    color:
                                                        Colors.red.shade700)),
                                          // Hoặc nếu chỉ muốn báo stock chung của sản phẩm:
                                          // else if (productDetail.stock < 1)
                                          //    Text("- Sản phẩm này đã hết hàng", style: TextStyle(color: Colors.red.shade700)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                            const SizedBox(height: 24),

                            // Quantity Selector
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
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
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
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Colors.grey),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Colors.brown,
                                                width: 1.5),
                                          ),
                                          disabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          if (isAddingToCart) return;
                                          if (value.isNotEmpty) {
                                            final newQuantity =
                                                int.tryParse(value);
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
                                      icon:
                                          const Icon(Icons.add_circle_outline),
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

                            // Add to Cart Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
                                            : anyProductOutOfStock) // Disable nếu đang load sản phẩm hoặc hết hàng
                                    ? null
                                    : addToCart,
                                child: isAddingToCart
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3),
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
                            const SizedBox(
                                height: 16), // Thêm khoảng trống ở cuối
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
