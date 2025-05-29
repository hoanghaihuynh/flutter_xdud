import 'package:flutter/material.dart';
import 'package:myproject/widgets/table_card.dart';
import './../models/table.dart'; // Điều chỉnh đường dẫn nếu cần
import './../services/table_service.dart'; // Điều chỉnh đường dẫn nếu cần

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final TableService _tableService = TableService();
  late Future<List<TableModel>> _tablesFuture;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  void _loadTables() {
    setState(() {
      _tablesFuture = _tableService.getAllTables();
    });
  }

  Future<void> _handleTableTap(TableModel table) async {
    if (table.status == 'available') {
      // Xác nhận trước khi đặt bàn
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Xác nhận đặt bàn'),
            content:
                Text('Bạn có chắc chắn muốn đặt bàn số ${table.tableNumber}?'),
            actions: <Widget>[
              TextButton(
                child: Text('Hủy'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text('Đặt bàn'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        try {
          // Dữ liệu để cập nhật trạng thái bàn
          Map<String, dynamic> updateData = {'status': 'occupied'};
          TableModel updatedTable =
              await _tableService.updateTable(table.id, updateData);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Đã đặt bàn ${updatedTable.tableNumber} thành công! Trạng thái: ${updatedTable.status}.'),
              backgroundColor: Colors.green,
            ),
          );
          _loadTables(); // Tải lại danh sách bàn để cập nhật UI
          // TODO: Có thể điều hướng đến màn hình khác hoặc thực hiện hành động tiếp theo
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi đặt bàn: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (table.status == 'occupied') {
      // Thông báo bàn đã được đặt hoặc cho phép các hành động khác (ví dụ: hủy đặt bởi admin)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bàn ${table.tableNumber} hiện đã được đặt.'),
          backgroundColor: Colors.orange,
        ),
      );
      // TODO: Nếu là admin/staff, có thể thêm tùy chọn chuyển về 'available' ở đây
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách bàn ăn'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTables,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: FutureBuilder<List<TableModel>>(
        future: _tablesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Không thể tải danh sách bàn: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có bàn nào.'));
          }

          final tables = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadTables(),
            child: GridView.builder(
              padding: const EdgeInsets.all(10.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Số cột trong grid, bạn có thể điều chỉnh
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio:
                    1.2, // Tỷ lệ chiều rộng/chiều cao của mỗi item
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return TableCard(
                  // Sử dụng TableCard widget
                  table: table,
                  onTap: () => _handleTableTap(table),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
