import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myproject/screen/orderDetails_screen.dart';
import 'package:myproject/models/carts.dart';
import 'package:myproject/screen/shop_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  // lấy user_id
  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      print('Error getting userId: $e');
      return null;
    }
  }

  // Call api lấy giỏ hàng theo user id
  Future<void> _fetchCart() async {
    try {
      final userId = await _getUserId();
      print('Fetched userId: $userId');

      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }

      final url =
          Uri.parse('http://172.20.12.120:3000/cart/getCartByUserId/$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Check for null and response structure
        if (responseData['data'] == null ||
            responseData['data']['products'] == null) {
          setState(() {
            _isLoading = false;
            _cartItems = [];
          });
          return;
        }

        final cartData = responseData['data']['products'] as List;

        setState(() {
          _cartItems = cartData.map((item) {
            try {
              return CartItem.fromJson(item);
            } catch (e) {
              print('Error parsing item: $e');
              // Return default CartItem if parsing fails
              return CartItem(
                id: item['_id'] ?? 'unknown',
                productId: item['productId']['_id'] ?? 'unknown_product',
                name: item['productId']['name'] ?? 'Unknown Product',
                price: (item['price'] ?? 0).toDouble(),
                quantity: item['quantity'] ?? 1,
                imageUrl: item['productId']['imageUrl'] ??
                    'https://via.placeholder.com/150',
              );
            }
          }).toList();
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load cart: ${response.statusCode}';
        });
      }
    } catch (error) {
      print('Error fetching cart: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading cart: ${error.toString()}';
      });
    }
  }

  // tính tổng giỏ hàng
  double get totalPrice {
    return _cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  // Format lại giá sản phẩm
  String formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return format.format(amount);
  }

  // Call api xóa sản phẩm khỏi giỏ hàng
  Future<void> _removeItem(String cartItemId, String productId) async {
    try {
      final userId = await _getUserId();

      print("userId: $userId, cartItemId: $cartItemId, productId: $productId");

      if (userId == null) {
        _showSnackBar('User not logged in', isError: true);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final url = Uri.parse('http://172.20.12.120:3000/cart/removeProduct/');
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'cartItemId': cartItemId,
          'productId': productId,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = json.decode(response.body);
      print('Response from remove: $responseData');

      if (response.statusCode == 200) {
        _showSnackBar(
          responseData['message'] ?? 'XÓA SẢN PHẨM KHỎI GIỎ HÀNG THÀNH CÔNG',
          isError: false,
        );
        _fetchCart(); // Refresh cart
      } else {
        _showSnackBar(
          responseData['error'] ?? 'Failed to remove item',
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error removing item: ${e.toString()}', isError: true);
    }
  }

  // thay đổi số lượng sp
  Future<void> _updateQuantity(String productId, int quantity) async {
    if (quantity < 1) return;

    try {
      final userId = await _getUserId();
      if (userId == null) return;

      setState(() {
        _isLoading = true;
      });

      final url =
          Uri.parse('http://172.20.12.120:3000/cart/updateCartQuantity');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'productId': productId,
          'newQuantity': quantity,
        }),
      );

      final responseData = jsonDecode(response.body);

      print('responseData: $responseData');

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        _fetchCart(); // Refresh cart after update
      } else {
        _showSnackBar('Failed to update quantity', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error updating quantity: ${e.toString()}', isError: true);
    }
  }

  // hiển thị thông báo khi thêm xóa sửa thành công
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // call api đặt hàng
  Future<void> _insertOrder() async {
    final userId = await _getUserId();

    if (userId == null || userId.isEmpty) {
      _showSnackBar('User not logged in', isError: true);
      return;
    }

    if (_cartItems.isEmpty) {
      _showSnackBar('Cart is empty', isError: true);
      return;
    }

    final List<Map<String, dynamic>> productList = _cartItems.map((item) {
      return {
        "product_id": item.productId,
        "quantity": item.quantity,
        "price": item.price
      };
    }).toList();

    final orderData = {
      "user_id": userId,
      "products": productList,
      "total": totalPrice,
      "status": "pending"
    };

    try {
      setState(() {
        _isLoading = true;
      });

      final url = Uri.parse('http://172.20.12.120:3000/order/insertOrder');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('ĐẶT HÀNG THÀNH CÔNG');
        await _clearCart(); // gọi hàm này để xóa giỏ hàng
      } else {
        _showSnackBar('Failed to place order: ${responseData['message']}',
            isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error placing order: $e', isError: true);
    }
  }

  // Call api clear giỏ hàng
  Future<void> _clearCart() async {
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      print('User ID not found for clearCart');
      return;
    }

    final url = Uri.parse('http://172.20.12.120:3000/cart/clearCart');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId}),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      print('Giỏ hàng đã được xóa thành công');
      _fetchCart(); // refresh UI
    } else {
      print('Lỗi khi xóa giỏ hàng: ${responseData['message']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Icon xem đơn hàng
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () async {
              final userId = await _getUserId();
              if (userId != null && userId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderListScreen(userId: userId),
                  ),
                );
              } else {
                _showSnackBar('Vui lòng đăng nhập để xem đơn hàng',
                    isError: true);
              }
            },
            tooltip: 'Xem đơn hàng',
          ),
          // Icon refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCart,
            tooltip: 'Làm mới giỏ hàng',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMainContent(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchCart,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShopScreen()));
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Continue Shopping'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            itemBuilder: (ctx, index) {
              final item = _cartItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCartItem(item),
              );
            },
          ),
        ),
        _buildCheckoutSection(),
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(item.price),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildQuantityControl(item),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeItem(item.id, item.productId),
                        tooltip: 'Remove item',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControl(CartItem item) {
    final TextEditingController _quantityController = TextEditingController(
      text: item.quantity.toString(),
    );

    return Container(
      width: 100, // Đặt chiều rộng cố định
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _quantityController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        style: const TextStyle(fontWeight: FontWeight.bold),
        onSubmitted: (value) {
          final newQuantity = int.tryParse(value) ?? item.quantity;
          if (newQuantity > 0 && newQuantity != item.quantity) {
            _updateQuantity(item.productId, newQuantity);
          } else {
            // Nếu giá trị không hợp lệ, khôi phục giá trị cũ
            _quantityController.text = item.quantity.toString();
          }
        },
        onEditingComplete: () {
          // Xử lý khi hoàn thành chỉnh sửa (tương tự onSubmitted)
          final value = _quantityController.text;
          final newQuantity = int.tryParse(value) ?? item.quantity;
          if (newQuantity > 0 && newQuantity != item.quantity) {
            _updateQuantity(item.productId, newQuantity);
          } else {
            _quantityController.text = item.quantity.toString();
          }
        },
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  formatCurrency(totalPrice),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shipping',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  'Free',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatCurrency(totalPrice),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _insertOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
