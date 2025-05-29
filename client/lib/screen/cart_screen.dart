import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myproject/screen/orderDetails_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import './../models/carts.dart'; // Assuming Cart model is here
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

  // Voucher related state
  final TextEditingController _voucherController = TextEditingController();
  String? _appliedVoucherCode;
  double _discountAmount = 0.0;
  double _finalPrice = 0.0; // Price after discount
  bool _isApplyingVoucher = false;

  @override
  void initState() {
    super.initState();
    _fetchCart().then((_) {
      _updateFinalPrice(); // Initialize final price after fetching cart
    });
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _fetchCart() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      // Reset voucher details when fetching cart
      _appliedVoucherCode = null;
      _discountAmount = 0.0;
      _voucherController.clear();
    });

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

      // Assuming fetchCartByUserId returns a List<CartItem> directly for now
      // If it returns a Cart object, you'll need to adjust
      final cartItems = await CartService.fetchCartByUserId(userId);

      if (mounted) {
        setState(() {
          _cartItems = cartItems;
          _isLoading = false;
          _errorMessage = null;
          _updateFinalPrice(); // Update final price after cart items are fetched/updated
        });
      }
    } catch (e) {
      print('Error fetching cart: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading cart: ${e.toString()}';
          _updateFinalPrice();
        });
      }
    }
  }

  double get subtotalPrice {
    return _cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity) + (item.toppingPrice * item.quantity), // Include topping price in subtotal
    );
  }

  void _updateFinalPrice() {
    if (mounted) {
      setState(() {
        _finalPrice = subtotalPrice - _discountAmount;
        if (_finalPrice < 0) {
          _finalPrice = 0;
        }
      });
    }
  }

  Future<void> _removeItem(String cartItemId, String productId) async {
    // ... (existing code) ...
    // After successful removal and _fetchCart():
    // _fetchCart calls _updateFinalPrice()
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
        await _fetchCart(); // Refresh cart and updates final price
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

  Future<void> _updateQuantity(String productId, int quantity) async {
    if (quantity < 1) return;
    // ... (existing code) ...
    // After successful update and _fetchCart():
    // _fetchCart calls _updateFinalPrice()
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
        await _fetchCart(); // Refresh cart and updates final price
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
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

  // Apply voucher
  Future<void> _applyVoucher() async {
    final voucherCode = _voucherController.text.trim();
    if (voucherCode.isEmpty) {
      _showSnackBar('Please enter a voucher code', isError: true);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isApplyingVoucher = true;
    });

    try {
      final userId = await getUserId();
      if (userId == null || userId.isEmpty) {
        _showSnackBar('User not logged in', isError: true);
        setState(() => _isApplyingVoucher = false);
        return;
      }
      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/cart/apply-voucher')), // Your backend endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'voucher_code': voucherCode}),
      );
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        final cartData = responseData['data']; // Assuming backend returns cart in 'data'
        if (mounted) {
          setState(() {
            _appliedVoucherCode = cartData['voucher_code'];
            _discountAmount = (cartData['discount_amount'] ?? 0.0).toDouble();
            _updateFinalPrice();
          });
        }
       _showSnackBar('Voucher applied successfully!', isError: false);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to apply voucher');
      }
      // --- End of Placeholder ---

      // Simulated API call for now
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay


    } catch (e) {
      if (mounted) {
        setState(() {
          _appliedVoucherCode = null;
          _discountAmount = 0.0;
          _updateFinalPrice();
        });
      }
      _showSnackBar('Error applying voucher: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingVoucher = false;
        });
      }
    }
  }


  Future<void> _insertOrder({
    String paymentMethod = "VNPAY", // Default, can be overridden
    String? orderId // For VNPAY, orderId might be generated before paymentUrl
  }) async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      final userId = await getUserId();

      if (userId == null || userId.isEmpty) {
        _showSnackBar('Vui lòng đăng nhập', isError: true);
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (_cartItems.isEmpty) {
        _showSnackBar('Giỏ hàng trống', isError: true);
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final productList = _cartItems.map((item) {
        return {
          "product_id": item.productId,
          "quantity": item.quantity,
          "price": item.price, // Original price per unit
          "toppingPrice": item.toppingPrice, // Topping price per unit
          "note": {
            "size": item.size,
            "sugarLevel": item.sugarLevel,
            "toppings": item.toppings,
          }
        };
      }).toList();

      final orderData = {
        "user_id": userId,
        "products": productList,
        "subtotal": subtotalPrice, // Send original subtotal
        "discount_amount": _discountAmount, // Send discount
        "voucher_code": _appliedVoucherCode, // Send applied voucher
        "total": _finalPrice, // Send final price after discount
        "payment_method": paymentMethod,
        "status": "pending", // Initial status
        "created_at": DateTime.now().toIso8601String(),
        if (orderId != null) "order_id": orderId, // Include if VNPAY generated one
      };

      debugPrint('Order Data to be sent: ${jsonEncode(orderData)}');

      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl('/order/insertOrder')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      ).timeout(const Duration(seconds: 20));

      final responseData = json.decode(response.body);
      print('Insert order response: $responseData');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (paymentMethod != "VNPAY") { // VNPAY has its own redirection
          _showSnackBar('ĐẶT HÀNG THÀNH CÔNG');
          await _clearCart(); // Clears cart and resets voucher
          if (mounted) Navigator.pop(context); // Close payment modal
        }
        // For VNPAY, success is handled in _processVNPayPayment after redirection
        return responseData; // Return data for VNPAY to get paymentUrl
      } else {
        throw responseData['message'] ?? 'Đặt hàng thất bại';
      }
    } catch (e) {
       _showSnackBar('Lỗi đặt hàng: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
       rethrow; // Rethrow to be caught by payment processing methods
    } finally {
      if (mounted && paymentMethod != "VNPAY") { // VNPAY handles its own loading state
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _clearCart() async {
    final userId = await getUserId();
    if (userId == null || userId.isEmpty) {
      print('User ID not found for clearCart');
      return;
    }

    final url = Uri.parse(AppConfig.getApiUrl('/cart/clearCart'));

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        print('Giỏ hàng đã được xóa thành công');
        if(mounted) {
          setState(() {
            _cartItems = [];
            _appliedVoucherCode = null;
            _discountAmount = 0.0;
            _voucherController.clear();
            _updateFinalPrice(); // This will set finalPrice to 0
          });
        }
        // _fetchCart(); // This will also reset voucher and update prices
      } else {
        print('Lỗi khi xóa giỏ hàng: ${responseData['message']}');
        _showSnackBar('Lỗi khi xóa giỏ hàng: ${responseData['message']}', isError: true);
      }
    } catch (e) {
       print('Lỗi khi xóa giỏ hàng: $e');
      _showSnackBar('Lỗi khi xóa giỏ hàng: ${e.toString()}', isError: true);
    }
  }

  Future<void> _processVNPayPayment() async {
    // Kiểm tra nếu giỏ hàng trống
    if (_cartItems.isEmpty) {
        _showSnackBar('Giỏ hàng trống. Không thể thanh toán.', isError: true);
        return;
    }
    try {
      setState(() => _isProcessingPayment = true);

      final userId = await getUserId();
      if (userId == null || userId.isEmpty) {
        _showSnackBar('Vui lòng đăng nhập để tiếp tục', isError: true);
        setState(() => _isProcessingPayment = false); // Thêm dòng này để dừng loading
        return;
      }

      // Chuẩn bị dữ liệu đơn hàng
      // QUAN TRỌNG: Đoạn tạo orderData này nên được thực hiện tập trung trong hàm _insertOrder
      // Tuy nhiên, để sửa lỗi trực tiếp cho đoạn code bạn cung cấp:
      final productList = _cartItems
          .map((item) => {
                "product_id": item.productId,
                "quantity": item.quantity,
                "price": item.price, // Giá gốc của sản phẩm
                // Nếu backend cần giá đã bao gồm topping ở đây, bạn cần điều chỉnh
                // Hoặc tốt hơn là backend tự tính toán dựa trên product_id và note
              })
          .toList();

      final orderData = {
        "user_id": userId,
        "products": productList,
        "subtotal": subtotalPrice, // Tổng tiền hàng gốc
        "discount_amount": _discountAmount, // Số tiền giảm giá
        "voucher_code": _appliedVoucherCode, // Mã voucher đã áp dụng
        "total": _finalPrice, // SỬ DỤNG _finalPrice THAY CHO totalPrice
        "payment_method": "VNPAY",
        "status": "pending" // Trạng thái ban đầu
      };

      // Gọi API tạo đơn hàng (Backend /order/insertOrder cần xử lý các trường mới này)
      final url = Uri.parse(AppConfig.getApiUrl('/order/insertOrder'));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Lấy paymentUrl từ response (Backend phải trả về paymentUrl trong data)
        final paymentUrl = responseData['data']?['paymentUrl'];

        if (paymentUrl == null) {
          throw 'Không nhận được URL thanh toán từ máy chủ.';
        }
        print("Payment URL: $paymentUrl");

        // Mở trình duyệt để thanh toán
        final uri = Uri.parse(paymentUrl); // Chuyển đổi String thành Uri
        if (await canLaunchUrl(uri)) { // Sử dụng canLaunchUrl
          await launchUrl(uri, mode: LaunchMode.externalApplication); // Sử dụng launchUrl
          _showSnackBar('Đang chuyển hướng đến VNPAY...');
          await _clearCart(); // Xóa giỏ hàng sau khi chuyển hướng
          if (mounted) Navigator.pop(context); // Đóng modal sau khi chuyển hướng
        } else {
          throw 'Không thể mở URL thanh toán: $paymentUrl';
        }
      } else {
        throw responseData['message'] ?? 'Tạo yêu cầu thanh toán thất bại';
      }
    } catch (e) {
      _showSnackBar('Lỗi thanh toán VNPAY: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    } finally {
      if (mounted) { // Kiểm tra mounted trước khi gọi setState
         setState(() => _isProcessingPayment = false);
      }
    }
  }

  Future<void> _processCashPayment() async {
    if (_cartItems.isEmpty) {
        _showSnackBar('Giỏ hàng trống. Không thể đặt hàng.', isError: true);
        return;
    }
    try {
      setState(() => _isProcessingPayment = true);
      await _insertOrder(paymentMethod: "CASH");
      // _insertOrder handles success message, cart clearing, and modal pop for CASH
    } catch (e) {
      // Error snackbar is shown in _insertOrder
      print('Cash payment processing failed: $e');
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
        totalAmount: _finalPrice, // Show final price in modal
        onPaymentMethodSelected: (method) async {
          if (method == 'VNPAY') {
            await _processVNPayPayment();
          } else { // CASH
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (){
              _fetchCart();
            } , // Refresh cart and voucher state
            tooltip: 'Làm mới giỏ hàng',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMainContent(),
          if (_isLoading || _isApplyingVoucher) // Show loader if general loading or applying voucher
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (_isApplyingVoucher) ...[
                      const SizedBox(height: 10),
                      const Text("Applying Voucher...", style: TextStyle(color: Colors.white, fontSize: 16))
                    ]
                  ],
                )
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_errorMessage != null && !_isLoading) { // Only show error if not loading
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

    if (_cartItems.isEmpty && !_isLoading) { // Only show empty cart if not loading
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
                Navigator.pop(context); // Go back to previous screen
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
    // Don't build list if loading, show loader from Stack
    if (_isLoading) return const SizedBox.shrink();


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
    // Calculate total price for this specific item including its own topping price and quantity
    // This is for display per item, not the cart's subtotal
    double itemDisplayTotalPrice = (item.price + item.toppingPrice) * item.quantity;

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
                      Text( // Price per unit without topping for clarity
                        '${formatCurrency(item.price)} / unit',
                        style: TextStyle(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: 14,
                        ),
                      ),
                      if (item.toppingPrice > 0) ... [
                        const SizedBox(height: 2),
                        Text( // Topping price per unit
                          '+${formatCurrency(item.toppingPrice)} toppings / unit',
                          style: TextStyle(
                            color: Colors.blueGrey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                       const SizedBox(height: 4),
                       Text( // Total for this item line (price + topping) * qty
                        formatCurrency(itemDisplayTotalPrice),
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
    // ... (existing code, no changes needed here) ...
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              // Topping price per item is already part of item.toppingPrice
              // It's included in the item's total price calculation
            ],
          ),
      ],
    );
  }

  Widget _buildQuantityControl(CartItem item) {
    // ... (existing code, but ensure it calls _updateFinalPrice after _updateQuantity) ...
    // _updateQuantity now calls _fetchCart which calls _updateFinalPrice
     final TextEditingController quantityController = TextEditingController(
      text: item.quantity.toString(),
    );
    // Set cursor to the end of the text
    quantityController.selection = TextSelection.fromPosition(TextPosition(offset: quantityController.text.length));


    return Container(
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: quantityController,
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
          } else if (newQuantity <=0) {
             _showSnackBar("Số lượng phải lớn hơn 0", isError: true);
             quantityController.text = item.quantity.toString();
          }
           else {
            quantityController.text = item.quantity.toString();
          }
        },
        // Consider adding onFocusChange or similar to update if user taps away
        // onEditingComplete is another option, similar to onSubmitted
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
            // Voucher Input
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48, // Consistent height
                      child: TextField(
                        controller: _voucherController,
                        decoration: InputDecoration(
                          hintText: 'Enter Voucher Code',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          suffixIcon: _appliedVoucherCode != null && _voucherController.text == _appliedVoucherCode
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[600]),
                                onPressed: () {
                                  if(mounted) {
                                    setState(() {
                                      _voucherController.clear();
                                      _appliedVoucherCode = null;
                                      _discountAmount = 0.0;
                                      _updateFinalPrice();
                                    });
                                  }
                                   _showSnackBar('Voucher removed.', isError: false);
                                },
                              )
                            : null,
                        ),
                        enabled: !_isApplyingVoucher, // Disable while applying
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isApplyingVoucher || _cartItems.isEmpty ? null : _applyVoucher,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(0, 48), // Match TextField height
                    ),
                    child: _isApplyingVoucher
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
                        : const Text('Apply'),
                  ),
                ],
              ),
            ),

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
                  formatCurrency(subtotalPrice),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Discount Row (only if discount is applied)
            if (_discountAmount > 0 && _appliedVoucherCode != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discount ($_appliedVoucherCode)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      '-${formatCurrency(_discountAmount)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),

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
                  'Free', // Or calculate shipping if applicable
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
                  formatCurrency(_finalPrice), // Use final price
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
                onPressed: _cartItems.isEmpty || _isProcessingPayment ? null : _showPaymentMethodModal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessingPayment
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                    : const Text(
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

// Placeholder for CartService.applyVoucher in your Flutter CartService file
// (e.g., services/cart_service.dart)
/*
class CartService {
  // ... other methods like fetchCartByUserId, removeItem, updateQuantity

  static Future<Map<String, dynamic>> applyVoucher({
    required String userId,
    required String voucherCode,
  }) async {
    final url = Uri.parse(AppConfig.getApiUrl('/cart/apply-voucher')); // Ensure this endpoint exists on your backend
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'voucher_code': voucherCode}),
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Assuming backend returns the updated cart object or relevant discount info
        // Example: { "success": true, "data": { "voucher_code": "CODE", "discount_amount": 5.0, "totalPriceAfterDiscount": 95.0, ... } }
        return responseData['data']; // Or however your backend structures success response
      } else {
        throw Exception(responseData['message'] ?? 'Failed to apply voucher');
      }
    } catch (e) {
      print('Error in CartService.applyVoucher: $e');
      throw Exception('Could not apply voucher: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}
*/