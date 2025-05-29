import 'package:flutter/material.dart';
import '../../services/order_service.dart'; // Điều chỉnh đường dẫn phù hợp

Future<void> showStatusUpdateDialog({
  required BuildContext context,
  required String orderId,
  required String currentStatus,
  required Function() onUpdateSuccess,
}) {
  final statuses = ['pending', 'completed', 'cancelled'];

  
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cập nhật trạng thái'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: statuses.map((status) {
          return ListTile(
            title: Text(status),
            trailing: currentStatus == status
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () async {
              Navigator.pop(context);
              try {
                final updatedOrder = await OrderService.updateOrder(
                  orderId: orderId,
                  updateData: {'status': status},
                );

                if (updatedOrder != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Cập nhật đơn hàng thành công')),
                  );
                  onUpdateSuccess(); // Callback để refresh danh sách
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi cập nhật: ${e.toString()}')),
                );
              }
            },
          );
        }).toList(),
      ),
    ),
  );
}
