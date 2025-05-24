import 'package:flutter/material.dart';
import 'package:myproject/admin/models/product_model.dart';
import 'package:myproject/admin/models/topping_model.dart';
import 'package:myproject/admin/services/product_service.dart';
import 'package:myproject/admin/services/topping_service.dart';
import 'package:myproject/admin/utils/format_currency.dart';

class EditProductDialog extends StatefulWidget {
  final Product product;
  final Function() onProductUpdated;

  const EditProductDialog({
    Key? key,
    required this.product,
    required this.onProductUpdated,
  }) : super(key: key);

  @override
  _EditProductDialogState createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late TextEditingController _imageUrlController;

  late List<String> _selectedSizes;
  late List<String> _selectedSugarLevels;
  late List<String> _selectedToppings;

  final List<String> _allSizes = ['M', 'L'];
  final List<String> _allSugarLevels = ['0 SG', '50 SG', '75 SG'];
  final ProductService _productService = ProductService();
  final ToppingService _toppingService = ToppingService();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _selectedSizes = List.from(widget.product.size);
    _selectedSugarLevels = List.from(widget.product.sugarLevel);
    _selectedToppings = List.from(widget.product.toppings);
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.name);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _stockController =
        TextEditingController(text: widget.product.stock.toString());
    _descController = TextEditingController(text: widget.product.description);
    _categoryController = TextEditingController(text: widget.product.category);
    _imageUrlController = TextEditingController(text: widget.product.imageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updateData = {
          'name': _nameController.text,
          'price': double.parse(_priceController.text),
          'stock': int.parse(_stockController.text),
          'description': _descController.text,
          'category': _categoryController.text,
          'imageUrl': _imageUrlController.text,
          'size': _selectedSizes,
          'sugarLevel': _selectedSugarLevels,
          'toppings': _selectedToppings,
        };

        await _productService.updateProduct(widget.product.id, updateData);

        Navigator.of(context).pop();
        widget.onProductUpdated();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật sản phẩm thành công!'),
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
    return AlertDialog(
      title: Text('Chỉnh sửa sản phẩm'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNameField(),
              SizedBox(height: 12),
              _buildPriceField(),
              SizedBox(height: 12),
              _buildStockField(),
              SizedBox(height: 12),
              _buildDescriptionField(),
              SizedBox(height: 12),
              _buildCategoryField(),
              SizedBox(height: 12),
              _buildImageUrlField(),
              SizedBox(height: 16),
              _buildSizeSelection(),
              SizedBox(height: 12),
              _buildSugarLevelSelection(),
              SizedBox(height: 12),
              _buildToppingsSelection(),
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
          child: Text('LƯU THAY ĐỔI'),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(labelText: 'Tên sản phẩm*'),
      validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: InputDecoration(
        labelText: 'Giá*',
        suffixText: '₫',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value!.isEmpty) return 'Vui lòng nhập giá';
        if (double.tryParse(value) == null) return 'Giá không hợp lệ';
        return null;
      },
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      decoration: InputDecoration(labelText: 'Số lượng*'),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value!.isEmpty) return 'Vui lòng nhập số lượng';
        if (int.tryParse(value) == null) return 'Số lượng không hợp lệ';
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descController,
      decoration: InputDecoration(labelText: 'Mô tả'),
      maxLines: 2,
    );
  }

  Widget _buildCategoryField() {
    return TextFormField(
      controller: _categoryController,
      decoration: InputDecoration(labelText: 'Danh mục*'),
      validator: (value) => value!.isEmpty ? 'Vui lòng nhập danh mục' : null,
    );
  }

  Widget _buildImageUrlField() {
    return TextFormField(
      controller: _imageUrlController,
      decoration: InputDecoration(labelText: 'URL hình ảnh'),
    );
  }

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kích thước:', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: _allSizes.map((size) {
            return FilterChip(
              label: Text(size),
              selected: _selectedSizes.contains(size),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSizes.add(size);
                  } else {
                    _selectedSizes.remove(size);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSugarLevelSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mức đường:', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: _allSugarLevels.map((level) {
            return FilterChip(
              label: Text(level),
              selected: _selectedSugarLevels.contains(level),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSugarLevels.add(level);
                  } else {
                    _selectedSugarLevels.remove(level);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildToppingsSelection() {
    return FutureBuilder<List<Topping>>(
      future: _toppingService.getAllToppings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Không thể tải danh sách toppings');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toppings:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: snapshot.data!.map((topping) {
                return FilterChip(
                  label: Text(topping.name),
                  selected: _selectedToppings.contains(topping.id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedToppings.add(topping.id);
                      } else {
                        _selectedToppings.remove(topping.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
