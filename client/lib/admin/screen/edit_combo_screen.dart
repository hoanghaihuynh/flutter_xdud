// File: screens/admin/edit_combo_screen.dart
import 'package:flutter/material.dart';
import '../../models/combo_model.dart';
// import '../../models/inserted_combo_data.dart';
import '../../models/products.dart';
import '../../services/combo_service.dart';
import '../../services/product_service.dart';

class EditComboScreen extends StatefulWidget {
  final Combo? initialCombo;

  const EditComboScreen({Key? key, this.initialCombo}) : super(key: key);

  @override
  State<EditComboScreen> createState() => _EditComboScreenState();
}

class _EditComboScreenState extends State<EditComboScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;

  // Danh sách ID sản phẩm được chọn cho combo hiện tại
  List<String> _selectedProductIdsForCombo = [];
  // Danh sách tất cả sản phẩm thường có sẵn để chọn
  List<Product> _availableRegularProducts = [];
  bool _isLoadingProducts = false; // Trạng thái tải sản phẩm thường

  bool _isSubmitting = false; // Trạng thái khi đang submit form
  final ApiService _apiService = ApiService();
  final ProductService _productService =
      ProductService(); // Service cho sản phẩm thường

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialCombo?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialCombo?.description ?? '');
    _priceController = TextEditingController(
        text: widget.initialCombo?.price.toString() ?? '');
    _imageUrlController =
        TextEditingController(text: widget.initialCombo?.imageUrl ?? '');

    if (widget.initialCombo != null) {
      _selectedProductIdsForCombo =
          widget.initialCombo!.products.map((p) => p.id).toList();
    }
    _fetchAllRegularProducts(); // Tải danh sách sản phẩm thường khi màn hình khởi tạo
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllRegularProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProducts = true;
    });
    try {
      final products = await _productService.fetchAllProducts();
      if (!mounted) return;
      setState(() {
        _availableRegularProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách sản phẩm: $e')),
      );
    }
  }

  Future<void> _showProductSelectionDialog() async {
    if (_isLoadingProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải danh sách sản phẩm...')),
      );
      return;
    }
    if (_availableRegularProducts.isEmpty) {
      // Có thể gọi lại _fetchAllRegularProducts nếu muốn thử lại
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Không có sản phẩm nào để chọn. Vui lòng thử lại.')),
      );
      await _fetchAllRegularProducts(); // Tải lại nếu rỗng
      if (_availableRegularProducts.isEmpty)
        return; // Vẫn rỗng thì không hiển thị dialog
    }

    final Set<String>? result = await showDialog<Set<String>>(
      context: context,
      builder: (BuildContext context) {
        return ProductSelectionDialog(
          availableProducts: _availableRegularProducts,
          initiallySelectedIds: Set<String>.from(_selectedProductIdsForCombo),
        );
      },
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        _selectedProductIdsForCombo = result.toList();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedProductIdsForCombo.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng chọn ít nhất một sản phẩm cho combo.')),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      String? userToken = "YOUR_ADMIN_AUTH_TOKEN"; // Lấy token thực tế

      final dataToSubmit = {
        "name": _nameController.text,
        "description": _descriptionController.text,
        "price": double.tryParse(_priceController.text) ?? 0,
        "imageUrl": _imageUrlController.text,
        "products": _selectedProductIdsForCombo, // Đây là List<String>
      };

      if (widget.initialCombo == null) {
        // TẠO MỚI COMBO
        // Giả sử hàm insertCombo của bạn nhận một Map<String, dynamic> hoặc các tham số riêng lẻ
        // Ở đây tôi truyền Map để giống cấu trúc request bạn cung cấp
        final newComboResponse = await _apiService.insertCombo(
          name: dataToSubmit['name'] as String,
          description: dataToSubmit['description'] as String,
          productIds: dataToSubmit['products'] as List<String>,
          imageUrl: dataToSubmit['imageUrl'] as String,
          price: dataToSubmit['price'] as double,
          authToken: userToken,
        ); // Giả sử hàm insertCombo trả về model response (ví dụ InsertedComboData)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Đã tạo combo "${newComboResponse.name}" thành công!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        // CẬP NHẬT COMBO
        final updatedComboResponse = await _apiService.updateCombo(
          comboId: widget.initialCombo!.id,
          name: dataToSubmit['name'] as String,
          description: dataToSubmit['description'] as String,
          productIds: dataToSubmit['products'] as List<String>,
          imageUrl: dataToSubmit['imageUrl'] as String,
          price: dataToSubmit['price'] as double,
          authToken: userToken,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Đã cập nhật combo "${updatedComboResponse.name}"!')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu combo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildSelectedProductsChips() {
    if (_selectedProductIdsForCombo.isEmpty) {
      return const Text('Chưa chọn sản phẩm nào cho combo.');
    }
    // Lấy tên sản phẩm từ _availableRegularProducts để hiển thị
    List<Widget> chips = _selectedProductIdsForCombo.map((id) {
      final product = _availableRegularProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => Product(
            id: id,
            name: 'ID: $id (Không tìm thấy tên)',
            price: 0,
            description: '',
            category: '',
            stock: 0,
            imageUrl: '',
            sizes: [],
            sugarLevels: [],
            toppingIds: []), // Product rỗng nếu không tìm thấy
      );
      return Chip(
        label: Text(product.name),
        onDeleted: () {
          if (!mounted) return;
          setState(() {
            _selectedProductIdsForCombo.remove(id);
          });
        },
      );
    }).toList();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: chips,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialCombo == null
            ? 'Thêm Combo Mới'
            : 'Sửa Combo "${widget.initialCombo?.name}"'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Lưu Combo',
            onPressed: _isSubmitting ? null : _submitForm,
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(
              child: CircularProgressIndicator(semanticsLabel: 'Đang lưu...'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch, // Cho nút bấm full width
                  children: <Widget>[
                    TextFormField(
                        /* ... Tên Combo ... */ controller: _nameController,
                        decoration: const InputDecoration(
                            labelText: 'Tên Combo',
                            border: OutlineInputBorder()),
                        validator: (v) =>
                            v!.isEmpty ? 'Không được bỏ trống' : null),
                    const SizedBox(height: 16),
                    TextFormField(
                      /* ... Mô tả ... */ controller: _descriptionController,
                      decoration: const InputDecoration(
                          labelText: 'Mô tả', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                        /* ... Giá ... */ controller: _priceController,
                        decoration: const InputDecoration(
                            labelText: 'Giá Combo',
                            border: OutlineInputBorder(),
                            prefixText: 'đ '),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v!.isEmpty) return 'Không được bỏ trống';
                          if (double.tryParse(v) == null ||
                              double.parse(v) <= 0) return 'Giá không hợp lệ';
                          return null;
                        }),
                    const SizedBox(height: 16),
                    TextFormField(
                      /* ... URL Hình ảnh ... */ controller:
                          _imageUrlController,
                      decoration: const InputDecoration(
                          labelText: 'URL Hình ảnh',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),
                    const Text('Sản phẩm trong Combo:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _isLoadingProducts
                        ? const Center(
                            child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("Đang tải danh sách sản phẩm...")))
                        : _buildSelectedProductsChips(), // Hiển thị sản phẩm đã chọn bằng Chip
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: const Text('Thêm/Sửa Sản Phẩm Trong Combo'),
                      onPressed: _showProductSelectionDialog,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text(widget.initialCombo == null
                          ? 'Tạo Combo'
                          : 'Lưu Thay Đổi'),
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// --- Widget Dialog Chọn Sản Phẩm ---
class ProductSelectionDialog extends StatefulWidget {
  final List<Product> availableProducts;
  final Set<String> initiallySelectedIds;

  const ProductSelectionDialog({
    Key? key,
    required this.availableProducts,
    required this.initiallySelectedIds,
  }) : super(key: key);

  @override
  State<ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<ProductSelectionDialog> {
  late Set<String> _tempSelectedProductIds;
  late List<Product> _displayProducts;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempSelectedProductIds = Set<String>.from(widget.initiallySelectedIds);
    _displayProducts = List<Product>.from(widget.availableProducts);
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _displayProducts = List<Product>.from(widget.availableProducts);
      } else {
        _displayProducts = widget.availableProducts
            .where((product) => product.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn Sản Phẩm Cho Combo'),
      content: SizedBox(
        // Giúp dialog có kích thước hợp lý
        width: double.maxFinite, // Chiếm toàn bộ chiều rộng có thể
        height: MediaQuery.of(context).size.height * 0.6, // Giới hạn chiều cao
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm tên sản phẩm...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: _displayProducts.isEmpty
                  ? const Center(child: Text('Không tìm thấy sản phẩm.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _displayProducts.length,
                      itemBuilder: (context, index) {
                        final product = _displayProducts[index];
                        final bool isSelected =
                            _tempSelectedProductIds.contains(product.id);
                        return CheckboxListTile(
                          title: Text(product.name),
                          subtitle: Text(
                              "${product.price.toStringAsFixed(0)}đ"), // Format giá nếu cần
                          value: isSelected,
                          onChanged: (bool? value) {
                            if (!mounted) return;
                            setState(() {
                              if (value == true) {
                                _tempSelectedProductIds.add(product.id);
                              } else {
                                _tempSelectedProductIds.remove(product.id);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Hủy'),
          onPressed: () =>
              Navigator.of(context).pop(null), // Trả về null nếu hủy
        ),
        ElevatedButton(
          child: const Text('Xong'),
          onPressed: () => Navigator.of(context)
              .pop(_tempSelectedProductIds), // Trả về danh sách ID đã chọn
        ),
      ],
    );
  }
}
