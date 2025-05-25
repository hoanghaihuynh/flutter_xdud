import 'package:flutter/material.dart';
// import 'package:myproject/admin/models/product_model.dart';
import 'package:myproject/admin/models/topping_model.dart';
import 'package:myproject/admin/services/product_service.dart';
import 'package:myproject/admin/services/topping_service.dart';
// import 'package:myproject/admin/utils/format_currency.dart';

class AddProductDialog extends StatefulWidget {
  final Function() onProductAdded;

  const AddProductDialog({
    Key? key,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final ToppingService _toppingService = ToppingService();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late TextEditingController _imageUrlController;

  // State for selections
  late List<String> _selectedSizes;
  late List<String> _selectedSugarLevels;
  late List<String> _selectedToppings;

  // Available options
  final List<String> _allSizes = ['M', 'L'];
  final List<String> _allSugarLevels = ['0 SL', '50 SL', '75 SL'];
  late Future<List<Topping>> _futureToppings;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _selectedSizes = ['M']; // Default value
    _selectedSugarLevels = ['0 SL']; // Default value
    _selectedToppings = [];
    _futureToppings = _toppingService.getAllToppings();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController();
    _descController = TextEditingController();
    _categoryController = TextEditingController();
    _imageUrlController = TextEditingController();
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
        final newProduct = {
          'name': _nameController.text,
          'price': double.parse(_priceController.text),
          'stock': int.parse(_stockController.text),
          'description': _descController.text,
          'category': _categoryController.text,
          'imageUrl': _imageUrlController.text.isNotEmpty 
              ? _imageUrlController.text 
              : 'https://via.placeholder.com/150',
          'size': _selectedSizes,
          'sugarLevel': _selectedSugarLevels,
          'toppings': _selectedToppings,
        };

        await _productService.createProduct(newProduct);
        
        Navigator.of(context).pop();
        widget.onProductAdded();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thêm sản phẩm mới thành công!'),
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
    return Dialog(
      insetPadding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Thêm sản phẩm mới',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                _buildNameField(),
                SizedBox(height: 16),
                _buildPriceField(),
                SizedBox(height: 16),
                _buildStockField(),
                SizedBox(height: 16),
                _buildCategoryField(),
                SizedBox(height: 16),
                _buildDescriptionField(),
                SizedBox(height: 16),
                _buildImageUrlField(),
                SizedBox(height: 20),
                _buildSizeSelection(),
                SizedBox(height: 16),
                _buildSugarLevelSelection(),
                SizedBox(height: 16),
                _buildToppingsSelection(),
                SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Tên sản phẩm*',
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

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockController,
      decoration: InputDecoration(
        labelText: 'Số lượng*',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value!.isEmpty) return 'Vui lòng nhập số lượng';
        if (int.tryParse(value) == null) return 'Số lượng không hợp lệ';
        return null;
      },
    );
  }

  Widget _buildCategoryField() {
    return TextFormField(
      controller: _categoryController,
      decoration: InputDecoration(
        labelText: 'Danh mục*',
        border: OutlineInputBorder(),
      ),
      validator: (value) => value!.isEmpty ? 'Vui lòng nhập danh mục' : null,
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

  Widget _buildImageUrlField() {
    return TextFormField(
      controller: _imageUrlController,
      decoration: InputDecoration(
        labelText: 'URL hình ảnh',
        border: OutlineInputBorder(),
        hintText: 'https://example.com/image.jpg',
      ),
    );
  }

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kích thước*:', style: TextStyle(fontWeight: FontWeight.bold)),
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
        Text('Mức đường*:', style: TextStyle(fontWeight: FontWeight.bold)),
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
      future: _futureToppings,
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('HỦY', style: TextStyle(color: Colors.red)),
        ),
        SizedBox(width: 16),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text('THÊM SẢN PHẨM'),
        ),
      ],
    );
  }
}