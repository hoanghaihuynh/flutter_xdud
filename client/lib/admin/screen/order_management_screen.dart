import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import './../models/order_model.dart';
import './../services/order_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await OrderService.getAllOrders();
      setState(() => _orders = orders);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      final success = await OrderService.deleteOrder(orderId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order deleted successfully')),
        );
        _loadOrders(); // Refresh list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete order: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('No orders found'))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(order);
                  },
                ),
    );
  }

  // Trong order_management_screen.dart
  Widget _buildOrderCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id.substring(0, 8)}'),
                Chip(
                  label: Text(order.status),
                  backgroundColor: _getStatusColor(order.status),
                ),
              ],
            ),
            Text('User: ${order.user.email}'),
            Text('Total: \$${order.total.toStringAsFixed(2)}'),
            if (order.paymentMethod != null)
              Text('Payment: ${order.paymentMethod}'),

            // Hiển thị sản phẩm đầu tiên
            if (order.products.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text('Products:'),
                  ...order.products
                      .take(2)
                      .map((product) => ListTile(
                            leading: product.product.imageUrl != null
                                ? Image.network(product.product.imageUrl!,
                                    width: 40)
                                : const Icon(Icons.fastfood),
                            title: Text(product.product.name),
                            subtitle: Text(
                                '${product.quantity} x \$${product.price}'),
                            trailing: Text(
                                '\$${(product.quantity * product.price).toStringAsFixed(2)}'),
                          ))
                      .toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'processing':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _confirmDelete(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOrder(orderId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
