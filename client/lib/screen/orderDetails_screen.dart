import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './../utils/formatCurrency.dart';
import './../models/orders.dart';
import './../services/order_service.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}', // Lấy 8 ký tự cuối hoặc toàn bộ ID nếu ngắn hơn
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Chip(
                  label: Text(
                    order.status.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: order.status.toLowerCase() == 'pending'
                      ? Colors.orange.shade700
                      : order.status.toLowerCase() == 'completed'
                          ? Colors.green.shade700
                          : order.status.toLowerCase() == 'cancelled'
                              ? Colors.red.shade700
                              : Colors.grey.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InfoRow(
                icon: Icons.calendar_today,
                text: DateFormat('dd/MM/yyyy HH:mm')
                    .format(order.createdAt.toLocal())),
            // InfoRow(icon: Icons.email, text: order.user.email), // Email có thể không cần thiết ở đây nếu đã có trong tài khoản người dùng

            // === HIỂN THỊ TÊN BÀN ===
            if (order.tableNumber != null && order.tableNumber!.isNotEmpty) ...[
              const SizedBox(height: 4), // Thêm khoảng cách nhỏ
              InfoRow(
                  icon: Icons.table_restaurant_outlined,
                  text: 'Table: ${order.tableNumber}',
                  highlight: true),
            ],
            // === KẾT THÚC HIỂN THỊ TÊN BÀN ===

            if (order.paymentMethod != null) ...[
              const SizedBox(height: 4),
              InfoRow(
                  icon: Icons.payment,
                  text: 'Payment: ${order.paymentMethod!.toUpperCase()}'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...order.products.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.quantity}x ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              item.product.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            // Hiển thị tổng tiền cho dòng sản phẩm này (giá * số lượng)
                            formatCurrency(item.price * item.quantity),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      // Hiển thị thông tin size, sugar level, toppings
                      if (item.note.size.isNotEmpty ||
                          item.note.sugarLevel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 4, left: 10), // Thụt vào một chút
                          child: Text(
                            "${item.note.size.isNotEmpty ? 'Size: ${item.note.size}' : ''}${item.note.size.isNotEmpty && item.note.sugarLevel.isNotEmpty ? ', ' : ''}${item.note.sugarLevel.isNotEmpty ? 'Sugar: ${item.note.sugarLevel.replaceAll(' SL', '%')}' : ''}",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ),
                      if (item.note.toppings.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Toppings:',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black54),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 10.0, top: 2.0),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 0,
                                  children: item.note.toppings.map((topping) {
                                    return Text(
                                      '• $topping', // Thêm dấu chấm đầu dòng
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    );
                                  }).toList(),
                                ),
                              ),
                              // Hiển thị tổng tiền topping cho dòng sản phẩm này (giá topping * số lượng)
                              if (item.note.toppingPrice > 0)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 2, left: 10.0),
                                  child: Text(
                                    '+ ${formatCurrency(item.note.toppingPrice * item.quantity)} (toppings)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColorDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                )),
            const Divider(height: 16, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  formatCurrency(order.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Theme.of(context).primaryColor,
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

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;

  const InfoRow({
    Key? key,
    required this.icon,
    required this.text,
    this.highlight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: highlight
                  ? Theme.of(context).primaryColorDark
                  : Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: highlight
                    ? Theme.of(context).primaryColorDark
                    : Colors.grey.shade700,
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
