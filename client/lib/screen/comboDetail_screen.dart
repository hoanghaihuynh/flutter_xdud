import 'package:flutter/material.dart';
import '../models/combo_model.dart';
import '../services/cart_service.dart';
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

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: quantity.toString());
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

  void addToCart() async {
    // Kiểm tra xem có sản phẩm nào trong combo đã hết hàng không
    bool productInComboOutOfStock = widget.combo.products.any((product) => product.stock < 1);

    if (productInComboOutOfStock) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Một hoặc nhiều sản phẩm trong combo này đã hết hàng.')),
        );
        return; // Không cho phép thêm vào giỏ nếu có sản phẩm hết hàng
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
      // Sử dụng _cartService để thêm vào giỏ hàng
      await _cartService.addComboToCart(widget.combo, quantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.combo.name} (x$quantity) đã được thêm vào giỏ hàng!')),
        );
        // Tùy chọn: Navigator.pop(context); // Quay lại màn hình trước đó
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm vào giỏ hàng: $e')),
        );
      }
    } finally {
      if (mounted) { // Kiểm tra widget còn mounted không trước khi gọi setState
        setState(() {
          isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra nếu có sản phẩm nào trong combo hết hàng để vô hiệu hóa nút thêm
    bool anyProductOutOfStock = widget.combo.products.any((p) => p.stock < 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.combo.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Combo Image
            AspectRatio(
              aspectRatio: 1.2, // Điều chỉnh tỷ lệ cho phù hợp hơn
              child: Hero( // Thêm Hero animation cho ảnh nếu có danh sách trước đó
                tag: 'combo_image_${widget.combo.id}',
                child: Image.network(
                  widget.combo.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, size: 100, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
            ),

            // Combo Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Combo Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.combo.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${widget.combo.price.toStringAsFixed(0)}đ',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  if (widget.combo.description.isNotEmpty) ...[
                    Text(
                      'Mô tả combo:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.combo.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],


                  // Products in Combo
                  Text(
                    'Bao gồm các sản phẩm:',
                     style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (widget.combo.products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Combo này hiện không có sản phẩm nào được liệt kê.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.combo.products.length,
                      itemBuilder: (context, index) {
                        final product = widget.combo.products[index];
                        bool productOutOfStock = product.stock < 1;
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: Image.network(
                                product.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: Icon(Icons.fastfood, color: Colors.grey[400]),
                                  );
                                },
                              ),
                            ),
                            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(
                                '${product.price.toStringAsFixed(0)}đ ${productOutOfStock ? "- Hết hàng" : ""}',
                                style: TextStyle(color: productOutOfStock ? Colors.red.shade700 : Colors.grey[600]),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.brown,
                            disabledColor: Colors.grey,
                            onPressed: isAddingToCart || quantity <= 1 ? null : () => _updateQuantity(quantity - 1),
                          ),
                          SizedBox(
                            width: 50, // Giảm chiều rộng của TextField
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              enabled: !isAddingToCart,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.brown, width: 1.5),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
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
                              onSubmitted: (value) { // Xử lý khi người dùng nhấn done trên bàn phím
                                if (isAddingToCart) return;
                                if (value.isEmpty || (int.tryParse(value) ?? 0) < 1) {
                                   _updateQuantity(1);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.brown,
                            disabledColor: Colors.grey,
                            onPressed: isAddingToCart ? null : () => _updateQuantity(quantity + 1),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.brown.withOpacity(0.5),
                      ),
                      onPressed: isAddingToCart || quantity < 1 || anyProductOutOfStock
                          ? null
                          : addToCart,
                      child: isAddingToCart
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : Text(
                              'Thêm vào giỏ hàng',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              )
                            ),
                    ),
                  ),
                   const SizedBox(height: 16), // Thêm khoảng trống ở cuối
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}