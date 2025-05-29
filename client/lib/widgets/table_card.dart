import 'package:flutter/material.dart';
import '../models/table.dart'; // Điều chỉnh đường dẫn nếu cần

class TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    IconData statusIcon;

    switch (table.status.toLowerCase()) {
      case 'available':
        cardColor = Colors.green.shade100;
        statusIcon = Icons.event_available_rounded;
        break;
      case 'occupied':
        cardColor = Colors.red.shade100;
        statusIcon = Icons.event_busy_rounded;
        break;
      default:
        cardColor = Colors.grey.shade200;
        statusIcon = Icons.table_restaurant_rounded;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    table.tableNumber,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Icon(statusIcon, color: Colors.black54),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                'Sức chứa: ${table.capacity} người',
                style: TextStyle(fontSize: 14.0, color: Colors.black87),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Trạng thái: ${table.status == "available" ? "Còn trống" : "Đã đặt"}',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: table.status == "available" ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
              if (table.description != null && table.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Mô tả: ${table.description}',
                    style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}