import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import './../models/orders.dart';

class OrderService {
  // static const String _baseUrl = 'http://192.168.242.234:3000/';

  Future<List<Order>> getOrdersByUserId(String userId) async {
    final response = await http.get(
      Uri.parse(
          'http://192.168.242.234:3000/order/getAllOrder?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 200) {
        return List<Order>.from(data['data'].map((x) => Order.fromJson(x)));
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load orders');
    }
  }
}

class OrderListScreen extends StatefulWidget {
  final String userId;

  const OrderListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late Future<List<Order>> futureOrders;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    futureOrders = _orderService.getOrdersByUserId(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
      ),
      body: FutureBuilder<List<Order>>(
        future: futureOrders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final order = snapshot.data![index];
                return OrderCard(order: order);
              },
            );
          }
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Chip(
                  label: Text(
                    order.status.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: order.status == 'pending'
                      ? Colors.orange
                      : order.status == 'completed'
                          ? Colors.green
                          : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${order.createdAt.toLocal().toString().split('.')[0]}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...order.products.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Text('${item.quantity}x '),
                      Expanded(child: Text(item.product.name)),
                      Text(
                        NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                            .format(item.price),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                      .format(order.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
