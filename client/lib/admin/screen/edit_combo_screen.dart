// File: screens/admin/edit_combo_screen.dart
import 'package:flutter/material.dart';
import '../../models/combo_model.dart'; // Model Combo và ProductItem
import '../../models/inserted_combo_data.dart'; // Model cho response của insert/update
import '../../services/combo_service.dart'; // Service của bạn

class EditComboScreen extends StatefulWidget {
  final Combo? initialCombo; // Combo hiện tại để sửa, null nếu là tạo mới

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
  List<String> _selectedProductIds =
      []; // Sẽ lưu ID các sản phẩm được chọn cho combo

  bool _isLoading = false;
  final ComboService _apiService = ComboService();

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

    if (widget.initialCombo != null &&
        widget.initialCombo!.products.isNotEmpty) {
      // Thêm kiểm tra products không rỗng
      _selectedProductIds = widget.initialCombo!.products
          .map((comboProductConfig) =>
              comboProductConfig.productId) // << SỬA Ở ĐÂY
          .toList();
    }
    // TODO: Thêm UI để chọn/quản lý _selectedProductIds
    // Đây là phần phức tạp nhất, có thể cần một dialog/multi-select widget
    // để admin chọn từ danh sách sản phẩm hiện có.
    // Ví dụ, bạn có thể fetch tất cả products và hiển thị trong một multi-select checkbox list.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // TODO: Lấy _selectedProductIds từ UI chọn sản phẩm của bạn.
      // Hiện tại đang dùng _selectedProductIds đã khởi tạo.
      // Ví dụ, nếu bạn có widget chọn sản phẩm:
      // final List<String> currentProductIds = getProductIdsFromSelectorWidget();

      // Kiểm tra dữ liệu cơ bản
      if (_selectedProductIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vui lòng chọn ít nhất một sản phẩm cho combo.')),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      try {
        String? userToken =
            "YOUR_ADMIN_AUTH_TOKEN"; // Lấy token thực tế của bạn

        if (widget.initialCombo == null) {
          // --- TRƯỜNG HỢP TẠO MỚI COMBO ---
          // Giả sử ApiService có hàm insertCombo phù hợp
          InsertedComboData newCombo = await _apiService.insertCombo(
            name: _nameController.text,
            description: _descriptionController.text,
            productIds: _selectedProductIds, // Gửi danh sách ID
            imageUrl: _imageUrlController.text,
            price: double.tryParse(_priceController.text) ?? 0,
            authToken: userToken,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Đã tạo combo "${newCombo.name}" thành công!')),
            );
            Navigator.pop(context, true); // Trả về true để báo hiệu có thay đổi
          }
        } else {
          // --- TRƯỜNG HỢP CẬP NHẬT COMBO ---
          InsertedComboData updatedCombo = await _apiService.updateCombo(
            comboId: widget.initialCombo!.id,
            name: _nameController.text,
            description: _descriptionController.text,
            productIds: _selectedProductIds, // Gửi danh sách ID
            imageUrl: _imageUrlController.text,
            price: double.tryParse(_priceController.text) ?? 0,
            authToken: userToken,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Đã cập nhật combo "${updatedCombo.name}"!')),
            );
            Navigator.pop(context, true); // Trả về true để báo hiệu có thay đổi
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.initialCombo == null ? 'Thêm Combo Mới' : 'Sửa Combo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _submitForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Tên Combo'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên combo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Giá Combo'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập giá';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Giá không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration:
                          const InputDecoration(labelText: 'URL Hình ảnh'),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),
                    const Text('Sản phẩm trong Combo:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    // TODO: Xây dựng UI để chọn và hiển thị sản phẩm cho combo
                    // Đây là một phần phức tạp, có thể dùng MultiSelectChipField,
                    // hoặc một ListView các CheckboxListTile từ danh sách sản phẩm của bạn.
                    // Hiện tại, chỉ hiển thị danh sách ID (nếu có) để minh họa
                    if (_selectedProductIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                            'IDs Sản phẩm đã chọn: ${_selectedProductIds.join(", ")}'),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                            'Chưa có sản phẩm nào được chọn. (Cần UI chọn sản phẩm)'),
                      ),

                    // Nút để mở dialog/màn hình chọn sản phẩm
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Mở UI chọn sản phẩm và cập nhật _selectedProductIds
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'UI chọn sản phẩm sẽ được thêm ở đây!')));
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Thêm/Sửa Sản Phẩm Trong Combo'),
                    ),

                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15)),
                        onPressed: _isLoading ? null : _submitForm,
                        child: Text(widget.initialCombo == null
                            ? 'Tạo Combo'
                            : 'Lưu Thay Đổi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
