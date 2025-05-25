import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myproject/screen/orderDetails_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import './../models/carts.dart';
import './../services/cart_service.dart';
import './../utils/getUserId.dart';
import './../utils/formatCurrency.dart';
import './../config/config.dart';
import './../widgets/paymentMethod_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  // Call api lấy giỏ hàng theo user id
  Future<void> _fetchCart() async {
    try {
      final userId = await getUserId();
      print('fetch userid trong cart: $userId');

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'User not logged in';
          });
        }
        return;
      }

      final cartItems =
          await CartService.fetchCartByUserId(userId); // Lỗi trong đây

      if (mounted) {
        setState(() {
          _cartItems = cartItems;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error fetching cart: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading cart: ${e.toString()}';
        });
      }
    }
  }

  // tính tổng giỏ hàng
  double get totalPrice {
    return _cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  // Call api xóa sản phẩm khỏi giỏ hàng
  Future<void> _removeItem(String cartItemId, String productId) async {
    try {
      final userId = await getUserId();

      print("userId: $userId, cartItemId: $cartItemId, productId: $productId");

      if (userId == null) {
        _showSnackBar('User not logged in', isError: true);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final result = await CartService.removeItem(
        userId: userId,
        cartItemId: cartItemId,
        productId: productId,
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = result['body'];
      final statusCode = result['statusCode'];

      print('Response from remove: $responseData');

      if (statusCode == 200) {
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
      final userId = await getUserId();
      if (userId == null) return;

      setState(() {
        _isLoading = true;
      });

      final result = await CartService.updateQuantity(
        userId: userId,
        productId: productId,
        newQuantity: quantity,
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = result['body'];
      final statusCode = result['statusCode'];

      print('responseData: $responseData');

      if (statusCode == 200) {
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
  Future<void> _insertOrder({String paymentMethod = "VNPAY"}) async {
    try {
      setState(() => _isLoading = true);
      final userId = await getUserId();

      if (userId == null || userId.isEmpty) {
        _showSnackBar('Vui lòng đăng nhập', isError: true);
        return;
      }

      if (_cartItems.isEmpty) {
        _showSnackBar('Giỏ hàng trống', isError: true);
        return;
      }

      final productList = _cartItems.map((item) {
        return {
          "product_id": item.productId,
          "quantity": item.quantity,
          "price": item.price + item.toppingPrice,
          "note": {
            "size": item.size,
            "sugarLevel": item.sugarLevel,
            "toppings": item.toppings,
            "toppingPrice": item.toppingPrice,
          }
        };
      }).toList();

      final orderData = {
        "user_id": userId,
        "products": productList,
        "total": totalPrice,
        "payment_method": paymentMethod,
        "status": "pending",
        "created_at": DateTime.now().toIso8601String(),
      };

      final response = await http
          .post(
            Uri.parse(AppConfig.getApiUrl('/order/insertOrder')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(orderData),
          )
          .timeout(const Duration(seconds: 15));

      final responseData = json.decode(response.body);
      print('insert order ne: $responseData');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('ĐẶT HÀNG THÀNH CÔNG');
        await _clearCart();
      } else {
        throw responseData['message'] ?? 'Đặt hàng thất bại';
      }
    } catch (e) {
      _showSnackBar('Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Call api clear giỏ hàng
  Future<void> _clearCart() async {
    final userId = await getUserId();
    if (userId == null || userId.isEmpty) {
      print('User ID not found for clearCart');
      return;
    }

    final url = Uri.parse(AppConfig.getApiUrl('/cart/clearCart'));

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

  // Xử lý thanh toán
  Future<void> _processVNPayPayment() async {
    try {
      setState(() => _isProcessingPayment = true);

      final userId = await getUserId();
      if (userId == null || userId.isEmpty) {
        _showSnackBar('Please login to continue', isError: true);
        return;
      }

      // Chuẩn bị dữ liệu đơn hàng
      final productList = _cartItems
          .map((item) => {
                "product_id": item.productId,
                "quantity": item.quantity,
                "price": item.price,
              })
          .toList();

      final orderData = {
        "user_id": userId,
        "products": productList,
        "total": totalPrice,
        "payment_method": "VNPAY",
        "status": "pending"
      };

      // Gọi API tạo đơn hàng
      final url = Uri.parse(AppConfig.getApiUrl('/order/insertOrder'));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Lấy paymentUrl từ response
        final paymentUrl = responseData['data']['paymentUrl'];
        // print("payment: $paymentUrl");

        // Mở trình duyệt để thanh toán
        if (await canLaunch(paymentUrl)) {
          await launch(paymentUrl);
          _showSnackBar('Redirecting to VNPAY...');
          await _clearCart();
          Navigator.pop(context); // Đóng modal sau khi chuyển hướng
        } else {
          throw 'Could not launch payment URL';
        }
      } else {
        throw responseData['message'] ?? 'Failed to create payment';
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _processCashPayment() async {
    try {
      setState(() => _isProcessingPayment = true);
      final userId = await getUserId();

      if (userId == null || userId.isEmpty) {
        _showSnackBar('Vui lòng đăng nhập để tiếp tục', isError: true);
        return;
      }

      final productList = _cartItems.map((item) {
        return {
          "product_id": item.productId,
          "quantity": item.quantity,
          "price": item.price + item.toppingPrice, // Bao gồm cả giá topping
          "note": {
            "size": item.size,
            "sugarLevel": item.sugarLevel,
            "toppings":
                item.toppings, // Sử dụng trường toppings thay vì toppingIds
            "toppingPrice": item.toppingPrice,
          }
        };
      }).toList();

      final orderData = {
        "user_id": userId,
        "products": productList,
        "total": totalPrice,
        "payment_method": "CASH",
        "status": "pending",
        "created_at": DateTime.now().toIso8601String(),
      };

      debugPrint('Order Data: ${jsonEncode(orderData)}');

      final response = await http
          .post(
            Uri.parse(AppConfig.getApiUrl('/order/insertOrder')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(orderData),
          )
          .timeout(const Duration(seconds: 15));

      final responseData = json.decode(response.body);
      print('insert order ne: $responseData');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Tạo đơn hàng thành công. Thanh toán khi nhận hàng');
        await _clearCart();
        Navigator.pop(context);
      } else {
        throw responseData['message'] ?? 'Tạo đơn hàng thất bại';
      }
    } catch (e) {
      _showSnackBar('Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  void _showPaymentMethodModal() {
    showDialog(
      context: context,
      builder: (context) => PaymentMethodModal(
        totalAmount: totalPrice,
        onPaymentMethodSelected: (method) async {
          if (method == 'VNPAY') {
            await _processVNPayPayment();
          } else {
            await _processCashPayment();
          }
        },
        isLoading: _isProcessingPayment,
      ),
    );
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
              final userId = await getUserId();
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
                Navigator.pop(context);
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
        child: Column(
          children: [
            Row(
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Hiển thị thông tin note
            _buildNoteInfo(item),
            const SizedBox(height: 12),
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
    );
  }

  Widget _buildNoteInfo(CartItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hiển thị size
        if (item.size.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.straighten, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Size: ${item.size}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

        // Hiển thị mức đường
        if (item.sugarLevel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.local_drink_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Đường: ${item.sugarLevel.replaceAll(' SL', '%')}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

        // Hiển thị topping nếu có
        if (item.toppings.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 16, thickness: 0.5),
              const Text(
                'Topping:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: item.toppings.map((topping) {
                  return Chip(
                    label: Text(topping),
                    backgroundColor: Colors.grey[200],
                    labelStyle: const TextStyle(fontSize: 12),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              if (item.toppingPrice > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${formatCurrency(item.toppingPrice)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
      ],
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
                onPressed: _showPaymentMethodModal,
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
