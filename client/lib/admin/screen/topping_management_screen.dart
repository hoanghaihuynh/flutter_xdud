import 'package:flutter/material.dart';
import 'package:myproject/admin/utils/format_currency.dart';
import './../dialogs/topping_dialog.dart'; // Thêm import này
import './../services/topping_service.dart';
import './../models/topping_model.dart';

class ToppingManagementScreen extends StatefulWidget {
  @override
  _ToppingManagementScreenState createState() =>
      _ToppingManagementScreenState();
}

class _ToppingManagementScreenState extends State<ToppingManagementScreen> {
  final ToppingService _toppingService = ToppingService();
  late Future<List<Topping>> _futureToppings;

  @override
  void initState() {
    super.initState();
    _loadToppings();
  }

  void _loadToppings() {
    setState(() {
      _futureToppings = _toppingService.getAllToppings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý Topping'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadToppings,
          ),
        ],
      ),
      body: _buildToppingList(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showToppingDialog(),
      ),
    );
  }

  Widget _buildToppingList() {
    return FutureBuilder<List<Topping>>(
      future: _futureToppings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Không có topping nào'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final topping = snapshot.data![index];
            return _buildToppingItem(topping);
          },
        );
      },
    );
  }

  Widget _buildToppingItem(Topping topping) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(topping.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${formatCurrency(topping.price)}'),
            if (topping.description.isNotEmpty) Text(topping.description),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showToppingDialog(topping: topping),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTopping(topping.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showToppingDialog({Topping? topping}) {
    showDialog(
      context: context,
      builder: (context) {
        return ToppingDialog(
          topping: topping,
          onSuccess: _loadToppings,
        );
      },
    );
  }

  Future<void> _deleteTopping(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa topping này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _toppingService.deleteTopping(id);
        _loadToppings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa topping thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa topping: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
