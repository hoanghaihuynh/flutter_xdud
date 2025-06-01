import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import './../utils/formatCurrency.dart';
import './../models/orders.dart';
import './../services/order_service.dart';
import 'package:printing/printing.dart'; // Import package printing
import 'dart:typed_data'; // Để dùng Uint8List
import './../utils/pdf_generator.dart';

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
  final InvoiceService _invoiceService = InvoiceService();

  OrderCard({Key? key, required this.order}) : super(key: key);

  Future<void> _printInvoice(BuildContext context, Order currentOrder) async {
    // Hiển thị loading (tùy chọn)
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));
    // print('OK NE'); OK

    try {
      // print('OK NE'); OK
      final Uint8List pdfBytes =
          await _invoiceService.generateInvoicePdf(currentOrder);

      Navigator.pop(context); // Tắt loading dialog

      // Sử dụng package printing để hiển thị print dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name:
            'HoaDon_${currentOrder.id.substring(currentOrder.id.length - 6)}.pdf', // Tên file mặc định khi lưu/chia sẻ
      );

      // Hoặc nếu bạn muốn chia sẻ file PDF:
      // await Printing.sharePdf(bytes: pdfBytes, filename: 'HoaDon_${currentOrder.id}.pdf');
    } catch (e) {
      print("PDF ga: $e");
      Navigator.pop(context); // Tắt loading dialog nếu có lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi khi tạo hóa đơn PDF: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

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

            const SizedBox(height: 16),
            const Divider(),
            // Nút In Hóa Đơn
            if (order.status.toLowerCase() == 'completed' ||
                order.status.toLowerCase() == 'pending' ||
                order.status.toLowerCase() ==
                    'occupied') // Ví dụ: Chỉ cho in khi đơn hàng đã hoàn thành hoặc đang chờ xử lý
              Center(
                // Đặt nút ở giữa hoặc vị trí bạn muốn
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('In Hóa Đơn'),
                  onPressed: () => {_printInvoice(context, order)},
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).primaryColor, // Màu nút
                      foregroundColor: Colors.white // Màu chữ
                      ),
                ),
              ),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
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
                              item.name, // <<--- THAY ĐỔI: item.product.name -> item.name
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            // Tổng tiền cho dòng này: item.price (giá 1 unit) * item.quantity
                            // Nếu item.price đã bao gồm topping price rồi thì không cần cộng item.toppingPrice nữa.
                            // Model OrderItem của chúng ta có item.price (chưa gồm topping) và item.toppingPrice (giá topping của 1 unit)
                            formatCurrency((item.price + item.toppingPrice) *
                                item.quantity),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      // Hiển thị thông tin size, sugar level, toppings
                      if (item.itemType == "PRODUCT" &&
                          (item.note.size?.isNotEmpty == true ||
                              item.note.sugarLevel?.isNotEmpty == true))
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 10),
                          child: Text(
                            "${item.note.size?.isNotEmpty == true ? 'Size: ${item.note.size}' : ''}"
                            "${item.note.size?.isNotEmpty == true && item.note.sugarLevel?.isNotEmpty == true ? ', ' : ''}"
                            "${item.note.sugarLevel?.isNotEmpty == true ? 'Sugar: ${item.note.sugarLevel!.replaceAll(' SL', '%')}' : ''}",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ),

                      // Hiển thị toppings (cho PRODUCT)
                      if (item.itemType == "PRODUCT" &&
                          item.note.toppings.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Toppings:',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 10.0, top: 2.0),
                                child: Column(
                                  // Hiển thị mỗi topping trên một dòng kèm giá
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: item.note.toppings.map((topping) {
                                    return Text(
                                      '• ${topping.name} (+${formatCurrency(topping.price)})', // <<--- THAY ĐỔI
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    );
                                  }).toList(),
                                ),
                              ),
                              // Tổng tiền topping đã được cộng vào dòng tổng ở trên thông qua item.toppingPrice
                            ],
                          ),
                        ),

                      // Hiển thị các sản phẩm con trong COMBO
                      if (item.itemType == "COMBO" &&
                          item.note.comboProductsSnapshot != null &&
                          item.note.comboProductsSnapshot!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chi tiết combo:',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic),
                              ),
                              ...item.note.comboProductsSnapshot!
                                  .map((snapshotItem) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(top: 2, left: 10),
                                  child: Text(
                                    '• ${snapshotItem.quantityInCombo}x ${snapshotItem.name}'
                                    '${snapshotItem.defaultSize?.isNotEmpty == true ? " (Size: ${snapshotItem.defaultSize})" : ""}'
                                    '${snapshotItem.defaultSugarLevel?.isNotEmpty == true ? " (${snapshotItem.defaultSugarLevel!.replaceAll(' SL', '%')})" : ""}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                );
                              }).toList(),
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
