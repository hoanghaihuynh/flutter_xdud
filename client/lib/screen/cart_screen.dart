import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myproject/models/carts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      print('Error getting userId: $e');
      return null;
    }
  }

  // Xem danh sách giỏ hàng theo User ID
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
          Uri.parse('http://192.168.1.5:3000/cart/getCartByUserId/$userId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Thêm kiểm tra null và cấu trúc response
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
              // Trả về một CartItem mặc định nếu parse lỗi
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

  double get totalPrice {
    return _cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  Future<void> _removeItem(String cartItemId, String productId) async {
    try {
      final userId = await _getUserId();

      print("userId: $userId, cartItemId: $cartItemId, productId: $productId");

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final url = Uri.parse('http://192.168.1.5:3000/cart/removeProduct/');
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'cartItemId': cartItemId, // Gửi cả ID cart item
          'productId': productId, // Và ID sản phẩm thực
        }),
      );

      final responseData = json.decode(response.body);
      print('Response from remove: $responseData');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'XÓA SẢN PHẨM THÀNH CÔNG'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchCart(); // Refresh lại giỏ hàng
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['error'] ?? 'Failed to remove item'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing item: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateQuantity(String id, int quantity) async {
    if (quantity < 1) return;

    try {
      final userId = await _getUserId();
      if (userId == null) return;

      final url = Uri.parse('http://192.168.1.5:3000/cart/updateQuantity');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'productId': id,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        _fetchCart(); // Refresh cart after update
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update quantity')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating quantity: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _cartItems.isEmpty
                  ? const Center(child: Text('Your cart is empty'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _cartItems.length,
                            itemBuilder: (ctx, index) {
                              final item = _cartItems[index];
                              return Card(
                                child: ListTile(
                                  leading: Image.network(
                                    item.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.error),
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text(
                                      '\$${item.price.toStringAsFixed(2)}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () => _updateQuantity(
                                            item.id, item.quantity - 1),
                                      ),
                                      Text(item.quantity.toString()),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () => _updateQuantity(
                                            item.id, item.quantity + 1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _removeItem(
                                            item.id, item.productId),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_cartItems.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total: \$${totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('Checkout'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}
