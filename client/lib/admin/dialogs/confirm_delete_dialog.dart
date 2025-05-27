import 'package:flutter/material.dart';

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'deliveried':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    case 'pending':
      return Colors.orange;
    default:
      return Colors.blue;
  }
}

Future<void> showConfirmDeleteDialog({
  required BuildContext context,
  required String orderId,
  required Function(String) onDelete,
}) {
  return showDialog(
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
            onDelete(orderId);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}