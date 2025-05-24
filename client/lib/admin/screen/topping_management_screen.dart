import 'package:flutter/material.dart';
import 'package:myproject/admin/utils/format_currency.dart';
import './../../admin/services/topping_service.dart';
import './../../admin/models/topping_model.dart';

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
      body: FutureBuilder<List<Topping>>(
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
              return ListTile(
                title: Text(topping.name),
                subtitle: Text(
                    '${formatCurrency(topping.price)} - ${topping.description}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditToppingDialog(topping),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTopping(topping.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddToppingDialog(),
      ),
    );
  }

  void _showAddToppingDialog() {
    // Tương tự như edit dialog nhưng không có giá trị ban đầu
    _showToppingDialog(isEditing: false);
  }

  void _showEditToppingDialog(Topping topping) {
    _showToppingDialog(isEditing: true, topping: topping);
  }

  void _showToppingDialog({bool isEditing = false, Topping? topping}) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: topping?.name ?? '');
    final _priceController =
        TextEditingController(text: topping?.price.toString() ?? '');
    final _descController =
        TextEditingController(text: topping?.description ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Chỉnh sửa topping' : 'Thêm topping mới'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Tên topping*'),
                    validator: (value) =>
                        value!.isEmpty ? 'Vui lòng nhập tên' : null,
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Giá*',
                      suffixText: '₫',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Vui lòng nhập giá';
                      if (double.tryParse(value) == null)
                        return 'Giá không hợp lệ';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(labelText: 'Mô tả'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final newTopping = Topping(
                      id: topping?.id ?? '',
                      name: _nameController.text,
                      price: double.parse(_priceController.text),
                      description: _descController.text,
                    );

                    if (isEditing && topping != null) {
                      await _toppingService.updateTopping(
                        topping.id,
                        newTopping.toJson(),
                      );
                    } else {
                      await _toppingService.createTopping(newTopping);
                    }

                    Navigator.pop(context);
                    _loadToppings();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing
                            ? 'Cập nhật topping thành công!'
                            : 'Thêm topping thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Lưu' : 'Thêm'),
            ),
          ],
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
