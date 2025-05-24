import 'package:flutter/material.dart';
import '../models/topping_model.dart';
import '../services/topping_service.dart';
// import '../utils/format_currency.dart';

class ToppingDialog extends StatefulWidget {
  final Topping? topping;
  final Function() onSuccess;

  const ToppingDialog({
    Key? key,
    this.topping,
    required this.onSuccess,
  }) : super(key: key);

  @override
  _ToppingDialogState createState() => _ToppingDialogState();
}

class _ToppingDialogState extends State<ToppingDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  final ToppingService _toppingService = ToppingService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.topping?.name ?? '');
    _priceController = TextEditingController(
      text: widget.topping?.price.toString() ?? '');
    _descController = TextEditingController(text: widget.topping?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final toppingData = Topping(
          id: widget.topping?.id ?? '',
          name: _nameController.text,
          price: double.parse(_priceController.text),
          description: _descController.text,
        );

        if (widget.topping != null) {
          await _toppingService.updateTopping(
            widget.topping!.id,
            toppingData.toJson(),
          );
        } else {
          await _toppingService.createTopping(toppingData);
        }

        Navigator.of(context).pop();
        widget.onSuccess();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.topping != null 
              ? 'Cập nhật topping thành công!' 
              : 'Thêm topping mới thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.topping != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'Chỉnh sửa topping' : 'Thêm topping mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNameField(),
              SizedBox(height: 16),
              _buildPriceField(),
              SizedBox(height: 16),
              _buildDescriptionField(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('HỦY', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text(isEditing ? 'LƯU' : 'THÊM'),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Tên topping*',
        border: OutlineInputBorder(),
      ),
      validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: InputDecoration(
        labelText: 'Giá*',
        suffixText: '₫',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value!.isEmpty) return 'Vui lòng nhập giá';
        if (double.tryParse(value) == null) return 'Giá không hợp lệ';
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descController,
      decoration: InputDecoration(
        labelText: 'Mô tả',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }
}